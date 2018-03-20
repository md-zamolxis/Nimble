#region Using

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Globalization;
using System.Reflection;
using System.Transactions;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Reflection;
using Nimble.Business.Engine.Common;
using Nimble.Business.Engine.Core;
using Hangfire;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008
{
    public abstract class GenericSql
    {
        #region Protected Members

        #region Properties

        protected string ConnectionString { get; private set; }

        #endregion Properties

        #region Methods

        protected GenericSql() { }

        protected GenericSql(string connectionString)
        {
            ConnectionString = connectionString;
        }

        protected static object MapParameter(object value)
        {
            if (value == null)
            {
                value = DBNull.Value;
            }
            else if (value is GenericEntity ||
                value is GenericPredicate)
            {
                value = EngineStatic.PortableXmlSerialize(value);
            }
            else if (value is IFormattable)
            {
                value = ((IFormattable)value).ToString(null, CultureInfo.InvariantCulture);
            }
            return value;
        }

        protected static object MapParameter(object value, PropertyInfo propertyInfo)
        {
            if (value != null &&
                propertyInfo.PropertyType.IsArray)
            {
                value = EngineStatic.PortableXmlSerialize(value);
            }
            else
            {
                value = MapParameter(value);
            }
            return value;
        }
        
        protected static void SetDbCommand(Session session, SqlConnection sqlConnection, DbCommand dbCommand)
        {
            if (session == null || session.TransactionScope == null)
            {
                sqlConnection.Open();
            }
            dbCommand.Connection = sqlConnection;
            if (Kernel.Instance.ServerConfiguration.DatabaseCommandTimeout.HasValue)
            {
                dbCommand.CommandTimeout = Kernel.Instance.ServerConfiguration.DatabaseCommandTimeout.Value;
            }
        }

        protected int? ExecuteRowCount(DbCommand dbCommand)
        {
            int? rowsAffected = null;
            var session = Kernel.Instance.SessionManager.SessionRead();
            var sqlConnection = session == null || session.TransactionScope == null ? new SqlConnection(ConnectionString) : session.SqlConnections[ConnectionString];
            try
            {
                SetDbCommand(session, sqlConnection, dbCommand);
                rowsAffected = dbCommand.ExecuteNonQuery();
            }
            catch (Exception exception)
            {
                HandleException(exception, dbCommand);
            }
            finally
            {
                if (session == null || session.TransactionScope == null)
                {
                    sqlConnection.Close();
                }
            }
            return rowsAffected;
        }

        protected bool ExecuteRowsAffected(DbCommand dbCommand)
        {
            return ExecuteRowCount(dbCommand) > 0;
        }

        protected object ExecuteScalar(DbCommand dbCommand)
        {
            object scalar = null;
            var session = Kernel.Instance.SessionManager.SessionRead();
            var sqlConnection = session == null || session.TransactionScope == null ? new SqlConnection(ConnectionString) : session.SqlConnections[ConnectionString];
            try
            {
                SetDbCommand(session, sqlConnection, dbCommand);
                scalar = dbCommand.ExecuteScalar();
                if (scalar == DBNull.Value)
                {
                    scalar = null;
                }
            }
            catch (Exception exception)
            {
                HandleException(exception, dbCommand);
            }
            finally
            {
                if (session == null || session.TransactionScope == null)
                {
                    sqlConnection.Close();
                }
            }
            return scalar;
        }

        protected void ExecuteNonQuery(DbCommand dbCommand, string connectionString = null)
        {
            connectionString = connectionString ?? ConnectionString;
            var session = Kernel.Instance.SessionManager.SessionRead();
            var sqlConnection = session == null || session.TransactionScope == null ? new SqlConnection(connectionString) : session.SqlConnections[connectionString];
            try
            {
                SetDbCommand(session, sqlConnection, dbCommand);
                dbCommand.ExecuteNonQuery();
            }
            catch (Exception exception)
            {
                HandleException(exception, dbCommand);
            }
            finally
            {
                if (session == null || session.TransactionScope == null)
                {
                    sqlConnection.Close();
                }
            }
        }

        protected DataSet ExecuteReader(DbCommand dbCommand, CommandBehavior commandBehavior = CommandBehavior.Default)
        {
            var dataSet = new DataSet();
            var session = Kernel.Instance.SessionManager.SessionRead();
            var sqlConnection = session == null || session.TransactionScope == null ? new SqlConnection(ConnectionString) : session.SqlConnections[ConnectionString];
            try
            {
                SetDbCommand(session, sqlConnection, dbCommand);
                var dataReader = dbCommand.ExecuteReader(commandBehavior);
                do
                {
                    var dataTable = new DataTable();
                    for (var index = 0; index < dataReader.FieldCount; index++)
                    {
                        var type = dataReader.GetFieldType(index);
                        if (type == null) continue;
                        dataTable.Columns.Add(dataReader.GetName(index), type);
                    }
                    while (dataReader.Read())
                    {
                        var dataRow = dataTable.NewRow();
                        for (var index = 0; index < dataReader.FieldCount; index++)
                        {
                            dataRow[index] = dataReader.GetValue(index);
                        }
                        dataTable.Rows.Add(dataRow);
                    }
                    dataSet.Tables.Add(dataTable);
                } while (dataReader.NextResult());
            }
            catch (Exception exception)
            {
                HandleException(exception, dbCommand);
            }
            finally
            {
                if (session == null || session.TransactionScope == null)
                {
                    sqlConnection.Close();
                }
            }
            return dataSet;
        }

        protected static Dictionary<string, int> GetDataReaderColumns<P>(IDataReader dataReader, Dictionary<string, int> columns, P predicate) where P : GenericPredicate
        {
            if (columns == null)
            {
                columns = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                var defined = predicate != null && predicate.Columns != null && predicate.Columns.Count > 0;
                for (var index = 0; index < dataReader.FieldCount; index++)
                {
                    var name = dataReader.GetName(index);
                    if (columns.ContainsKey(name) ||
                        (defined &&
                        !predicate.Columns.Contains(name))) continue;
                    columns.Add(name, index);
                }
            }
            return columns;
        }

        protected static object GetDataReaderValue(DatabaseColumn databaseColumn, IDataReader dataReader, Dictionary<string, int> columns, string prefix)
        {
            object value = null;
            if (databaseColumn != null)
            {
                var name = prefix + databaseColumn.Name;
                if (columns.ContainsKey(name))
                {
                    var index = columns[name];
                    value = dataReader.GetValue(index);
                    if (dataReader.IsDBNull(index) ||
                        (dataReader.GetFieldType(index).IsArray &&
                         ((Array)value).Length == 0))
                    {
                        value = null;
                    }
                }
            }
            return value;
        }
        
        protected static void SetPropertyDeclaratorValue(object propertyValue, PropertyDeclarator propertyDeclarator, object entity)
        {
            string propertyString = null;
            Type propertyType = null;
            if (propertyValue != null)
            {
                propertyString = propertyValue.ToString();
                propertyType = propertyValue.GetType();
            }
            if (propertyValue == DBNull.Value)
            {
                if (!propertyDeclarator.PropertyInfo.PropertyType.IsValueType ||
                    (propertyDeclarator.PropertyInfo.PropertyType.IsGenericType &&
                    propertyDeclarator.PropertyInfo.PropertyType.GetGenericTypeDefinition() == ClientStatic.Nullable))
                {
                    propertyDeclarator.SetValue(entity, null);
                }
            }
            else
            {
                var nullableType = Nullable.GetUnderlyingType(propertyDeclarator.PropertyInfo.PropertyType);
                if (propertyDeclarator.PropertyInfo.PropertyType.IsGenericType &&
                    nullableType != null &&
                    nullableType.IsEnum)
                {
                    if (!string.IsNullOrEmpty(propertyString) &&
                        Enum.IsDefined(nullableType, propertyValue))
                    {
                        propertyDeclarator.SetValue(entity, Enum.Parse(nullableType, propertyString, true));
                    }
                }
                else if (propertyDeclarator.PropertyInfo.PropertyType.IsEnum)
                {
                    if (!string.IsNullOrEmpty(propertyString) &&
                        Enum.IsDefined(propertyDeclarator.PropertyInfo.PropertyType, propertyValue))
                    {
                        propertyDeclarator.SetValue(entity, Enum.Parse(propertyDeclarator.PropertyInfo.PropertyType, propertyString, true));
                    }
                }
                else if (propertyDeclarator.PropertyInfo.PropertyType.IsGenericType &&
                    propertyDeclarator.PropertyInfo.PropertyType.GetGenericTypeDefinition() == ClientStatic.Flags)
                {
                    if (propertyType == ClientStatic.ValueInt)
                    {
                        propertyDeclarator.SetValue(entity, Activator.CreateInstance(propertyDeclarator.PropertyInfo.PropertyType, Convert.ToInt32(propertyValue)));
                    }
                    else if (propertyType == ClientStatic.ValueString)
                    {
                        propertyDeclarator.SetValue(entity, Activator.CreateInstance(propertyDeclarator.PropertyInfo.PropertyType, propertyString));
                    }
                }
                else if (propertyDeclarator.PropertyInfo.PropertyType.IsArray &&
                    propertyDeclarator.PropertyInfo.PropertyType.GetElementType() != ClientStatic.ValueByte)
                {
                    var elementType = propertyDeclarator.PropertyInfo.PropertyType.GetElementType();
                    if (!string.IsNullOrEmpty(propertyString) &&
                        elementType != null)
                    {
                        var xmlArrayTag = elementType.Name;
                        if (elementType.IsGenericType &&
                            elementType.GetGenericTypeDefinition() == ClientStatic.Nullable)
                        {
                            var underlyingType = Nullable.GetUnderlyingType(elementType);
                            if (underlyingType != null)
                            {
                                xmlArrayTag = ClientStatic.Transpose(underlyingType.Name, Constants.NUMERIC_SYMBOLS, null);
                            }
                        }
                        xmlArrayTag = string.Format(Constants.XML_ARRAY_TAG, xmlArrayTag, propertyString);
                        propertyDeclarator.SetValue(entity, EngineStatic.XmlDeserialize(xmlArrayTag, propertyDeclarator.PropertyInfo.PropertyType));
                    }
                }
                else if (propertyDeclarator.IsGenericPredicate)
                {
                    if (!string.IsNullOrEmpty(propertyString))
                    {
                        propertyDeclarator.SetValue(entity, EngineStatic.XmlDeserialize(propertyString, propertyDeclarator.PropertyInfo.PropertyType));
                    }
                }
                else
                {
                    propertyDeclarator.SetValue(entity, propertyValue);
                }
            }
        }

        protected static object EntityMap(Type initial, Type current, IDataReader dataReader, Dictionary<string, int> columns, DatabaseColumn databaseColumn, GenericCache genericCache, bool enableCache)
        {
            object entity = null;
            var typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(current);
            var isCached = enableCache && Kernel.Instance.GenericCache.EntityIsCached(current);
            var prefix = databaseColumn == null ? null : databaseColumn.Prefix;
            object cachedEntity = null;
            if (typeDeclarator.Identity != null)
            {
                cachedEntity = ClientStatic.CreateInstance(current);
                var propertyValue = GetDataReaderValue(typeDeclarator.Identity.DatabaseColumn, dataReader, columns, prefix);
                if (propertyValue != null)
                {
                    SetPropertyDeclaratorValue(propertyValue, typeDeclarator.Identity, cachedEntity);
                }
            }
            if (genericCache != null &&
                cachedEntity != null)
            {
                entity = genericCache.Get(cachedEntity);
            }
            if (entity == null)
            {
                if ((databaseColumn == null ||
                     !databaseColumn.DisableCaching) &&
                    isCached &&
                    cachedEntity != null)
                {
                    entity = Kernel.Instance.GenericCache.Get(cachedEntity);
                }
                if (entity == null)
                {
                    entity = ClientStatic.CreateInstance(current);
                }
                foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
                {
                    object propertyValue;
                    if (propertyDeclarator.IsGenericEntity)
                    {
                        var propertyType = propertyDeclarator.PropertyInfo.PropertyType;
                        if ((propertyDeclarator.DatabaseColumn == null ||
                             !propertyDeclarator.DatabaseColumn.DisableMapping) &&
                            (databaseColumn == null ||
                             databaseColumn.DisableMappings.Find(item => item == propertyType) == null))
                        {
                            var prefixDatabaseColumn = propertyDeclarator.DatabaseColumn;
                            if (!string.IsNullOrEmpty(prefix) &&
                                (databaseColumn.BlockPrefix == null ||
                                databaseColumn.BlockPrefix != propertyType))
                            {
                                prefixDatabaseColumn = databaseColumn;
                            }
                            propertyValue = EntityMap(initial, propertyType, dataReader, columns, prefixDatabaseColumn, genericCache, enableCache);
                            propertyDeclarator.SetValue(entity, propertyValue);
                        }
                    }
                    else
                    {
                        propertyValue = GetDataReaderValue(propertyDeclarator.DatabaseColumn, dataReader, columns, prefix);
                        if (propertyDeclarator.DatabaseColumn != null)
                        {
                            SetPropertyDeclaratorValue(propertyValue, propertyDeclarator, entity);
                        }
                    }
                }
                var genericEntity = entity as GenericEntity;
                if (typeDeclarator.Identity != null &&
                    typeDeclarator.Identity.DatabaseColumn != null &&
                    !typeDeclarator.Identity.DatabaseColumn.ForceValue &&
                    (databaseColumn == null || 
                     !databaseColumn.ForceValue) &&
                    !GenericEntity.HasValue(genericEntity))
                {
                    entity = null;
                }
                else if ((databaseColumn == null ||
                          !databaseColumn.DisableCaching) &&
                         isCached)
                {
                    Kernel.Instance.GenericCache.Add(entity);
                }
                if (genericCache != null &&
                    entity != null &&
                    current != initial)
                {
                    genericCache.Add(entity);
                }
            }
            return entity;
        }

        protected static void HandleException(Exception exception, DbCommand dbCommand)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            var databaseConstraintConfiguration = Kernel.Instance.ServerConfiguration.DatabaseConstraintFind(exception.Message);
            if (databaseConstraintConfiguration != null)
            {
                if (exception.Message.IndexOf(Constants.SQL_INSERT_ERROR_GENERIC_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    faultExceptionDetail.Code = databaseConstraintConfiguration.Insert;
                }
                if (exception.Message.IndexOf(Constants.SQL_UPDATE_ERROR_GENERIC_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    faultExceptionDetail.Code = databaseConstraintConfiguration.Update;
                }
                if (exception.Message.IndexOf(Constants.SQL_DELETE_ERROR_GENERIC_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    faultExceptionDetail.Code = databaseConstraintConfiguration.Delete;
                }
            }
            if (string.IsNullOrEmpty(faultExceptionDetail.Code))
            {
                if (exception.Message.IndexOf(Constants.SQL_INSERT_ERROR_GENERIC_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0 ||
                    exception.Message.IndexOf(Constants.SQL_UPDATE_ERROR_GENERIC_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    var propertyDeclarator = Kernel.Instance.TypeDeclaratorManager.FindByDatabaseColumn(exception.Message);
                    if (propertyDeclarator == null)
                    {
                        faultExceptionDetail.Code = Constants.SQL_ENTITY_PROPERTIES_NOT_UNIQUE_OR_NOT_VALID_MESSAGE;
                        faultExceptionDetail.Parameters = new object[]
                        {
                            exception.Message
                        };
                    }
                    else
                    {
                        faultExceptionDetail.Code = Constants.OBJECT_NOT_DEFINED;
                        faultExceptionDetail.Parameters = new object[]
                        {
                            propertyDeclarator.DatabaseColumn.IsIdentity ? Kernel.Instance.TypeDeclaratorManager.Get(propertyDeclarator.EntityType).DisplayName.Name : propertyDeclarator.DatabaseColumn.Name
                        };
                    }
                }
                else if (exception.Message.IndexOf(Constants.SQL_VIOLATION_ERROR_GENERIC_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    faultExceptionDetail.Code = Constants.SQL_ENTITY_PROPERTIES_NOT_UNIQUE_OR_NOT_VALID_MESSAGE;
                    faultExceptionDetail.Parameters = new object[]
                    {
                        exception.Message
                    };
                }
                else if (exception.Message.IndexOf(Constants.SQL_UNMATCHED_OR_NOT_FOUND_ENTITY_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    faultExceptionDetail.Code = Constants.SQL_UNMATCHED_OR_NOT_FOUND_ENTITY_MESSAGE;
                }
                else if (exception.Message.IndexOf(Constants.SQL_DELETE_ERROR_GENERIC_MESSAGE, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    faultExceptionDetail.Code = "Entity is referenced and cannot be deleted.";
                }
                else
                {
                    faultExceptionDetail.Code = "Data access error - see application log for details.";
                    var message = string.Empty;
                    if (dbCommand != null)
                    {
                        var parameters = string.Empty;
                        foreach (DbParameter parameter in dbCommand.Parameters)
                        {
                            var value = parameter.Value == null ? string.Empty : parameter.Value.ToString();
                            if (value.Length >= Int16.MaxValue)
                            {
                                value = value.Substring(0, byte.MaxValue);
                            }
                            parameters += string.Format("<br>name - {0}, value - {1}", parameter.ParameterName, value);
                        }
                        message += string.Format("<br>Database command exception - message: {0}; command text: {1}; command timeout: {2}; command type: {3}; parameters: {4}",
                            exception.Message,
                            dbCommand.CommandText,
                            dbCommand.CommandTimeout,
                            dbCommand.CommandType,
                            parameters);
                    }
                    var sqlException = exception as SqlException;
                    if (sqlException != null)
                    {
                        message += string.Format("<br>SQL exception - class: {0}; line number: {1}; number: {2}; procedure: {3}; server: {4}; state: {5}",
                            sqlException.Class,
                            sqlException.LineNumber,
                            sqlException.Number,
                            sqlException.Procedure,
                            sqlException.Server,
                            sqlException.State);
                    }
                    if (string.IsNullOrEmpty(message))
                    {
                        Kernel.Instance.Logging.Error(exception, false);
                    }
                    else
                    {
                        Kernel.Instance.Logging.Error(message, false);
                    }
                }
            }
            throw FaultExceptionDetail.Create(faultExceptionDetail);
        }

        protected GenericOutput<T> EntityAction<T, P>(string storedProcedureName, GenericInput<T, P> genericInput) where T : GenericEntity where P : GenericPredicate
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (session != null &&
                session.Token != null)
            {
                var coordinates = GenericEntity.GetCoordinates(session.Token.ClientGeospatial);
                if (coordinates != null)
                {
                    genericInput.Latitude = coordinates.Item1;
                    genericInput.Longitude = coordinates.Item2;
                }
            }
            var genericOutput = new GenericOutput<T>
            {
                PermissionType = genericInput.PermissionType,
                Pager = new Pager(),
                Entities = new List<T>(),
                QueryStart = DateTimeOffset.Now
            };
            if (genericInput.Predicate != null &&
                genericInput.Predicate.Pager != null)
            {
                genericOutput.Pager = genericInput.Predicate.Pager;
            }
            var sqlCommand = new SqlCommand
            {
                CommandText = storedProcedureName,
                CommandType = CommandType.StoredProcedure
            };
            sqlCommand.Parameters.AddWithValue("@genericInput", EngineStatic.PortableXmlSerialize(genericInput));
            var number = new SqlParameter
            {
                ParameterName = "@number",
                Direction = ParameterDirection.Output,
                DbType = DbType.Int32
            };
            sqlCommand.Parameters.Add(number);
            var type = typeof(T);
            var sqlConnection = session == null || session.TransactionScope == null ? new SqlConnection(ConnectionString) : session.SqlConnections[ConnectionString];
            try
            {
                SetDbCommand(session, sqlConnection, sqlCommand);
                using (var dataReader = sqlCommand.ExecuteReader())
                {
                    Dictionary<string, int> columns = null;
                    var genericCache = new GenericCache();
                    var enableCache = genericInput.Predicate == null || genericInput.Predicate.Columns == null || genericInput.Predicate.Columns.Count == 0;
                    while (dataReader.Read())
                    {
                        columns = GetDataReaderColumns(dataReader, columns, genericInput.Predicate);
                        genericOutput.Entities.Add((T)EntityMap(type, type, dataReader, columns, null, genericCache, enableCache));
                    }
                }
                if (number.Value != DBNull.Value)
                {
                    genericOutput.Pager.Number = (int)number.Value;
                }
            }
            catch (Exception exception)
            {
                HandleException(exception, sqlCommand);
            }
            finally
            {
                if (session == null || session.TransactionScope == null)
                {
                    sqlConnection.Close();
                }
                genericOutput.QueryEnd = DateTimeOffset.Now;
            }
            if (genericOutput.Entities.Count > 0)
            {
                genericOutput.Entity = genericOutput.Entities[0];
                genericOutput.Pager.Count = genericOutput.Entities.Count;
            }
            if (session != null && 
                session.Token != null && 
                genericOutput.QueryStart.Add(Kernel.Instance.SessionManager.SessionContext.SqlCommandDelay) <= genericOutput.QueryEnd)
            {
                var sqlParameters = new Dictionary<string, object>();
                foreach (SqlParameter sqlParameter in sqlCommand.Parameters)
                {
                    sqlParameters.Add(sqlParameter.ParameterName, sqlParameter.Value);
                }
                if (Kernel.Instance.ServerConfiguration.HangfireDisabled)
                {
                    SqlCommandDelay(session.Token, genericOutput, sqlCommand.CommandText, sqlParameters, null);
                }
                else
                {
                    using (var transactionScope = new TransactionScope(TransactionScopeOption.Suppress))
                    {
                        BackgroundJob.Enqueue(() => SqlCommandDelay(session.Token, genericOutput, sqlCommand.CommandText, sqlParameters, ConnectionString));
                        transactionScope.Complete();
                    }
                }
            }
            return genericOutput;
        }

        protected GenericOutput<T> EntityAction<T, P>(Type type, GenericInput<T, P> genericInput) where T : GenericEntity where P : GenericPredicate
        {
            return EntityAction(Kernel.Instance.TypeDeclaratorManager.Get(type).DatabaseMapping.StoredProcedure, genericInput);
        }

        protected GenericOutput<T> EntityAction<T, P>(GenericInput<T, P> genericInput) where T : GenericEntity where P : GenericPredicate
        {
            return EntityAction(Kernel.Instance.TypeDeclaratorManager.Get(typeof(T)).DatabaseMapping.StoredProcedure, genericInput);
        }

        protected GenericOutput<T> EntityAction<T>(string storedProcedureName, PermissionType permissionType, T entity) where T : GenericEntity
        {
            return EntityAction(storedProcedureName, new GenericInput<T, GenericPredicate>
            {
                PermissionType = permissionType,
                Entity = entity
            });
        }

        protected GenericOutput<T> EntityAction<T>(PermissionType permissionType, T entity) where T : GenericEntity
        {
            return EntityAction(Kernel.Instance.TypeDeclaratorManager.Get(typeof(T)).DatabaseMapping.StoredProcedure, permissionType, entity);
        }

        protected bool EntityDelete<T>(PermissionType permissionType, T entity) where T : GenericEntity
        {
            return EntityDelete(EntityAction(permissionType, entity).Pager.Number > 0, entity);
        }

        protected bool EntityDelete<T, P>(GenericInput<T, P> genericInput) where T : GenericEntity where P : GenericPredicate
        {
            return EntityDelete(EntityAction(genericInput).Pager.Number > 0, genericInput.Entity);
        }

        protected bool EntityDelete<T>(bool deleted, T entity) where T : GenericEntity
        {
            if (deleted &&
                Kernel.Instance.GenericCache.EntityIsCached(typeof(T)))
            {
                Kernel.Instance.GenericCache.Remove(entity);
            }
            return deleted;
        }

        protected Dictionary<E, T> GetEnumEntityPairs<E, T>(DbCommand dbCommand)
        {
            var enumEntityPairs = new Dictionary<E, T>();
            var enumType = typeof(E);
            var entityType = typeof(T);
            var typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(entityType);
            var propertyDeclarator = typeDeclarator.Find(enumType);
            if (propertyDeclarator != null)
            {
                var session = Kernel.Instance.SessionManager.SessionRead();
                var sqlConnection = session == null || session.TransactionScope == null ? new SqlConnection(ConnectionString) : session.SqlConnections[ConnectionString];
                try
                {
                    SetDbCommand(session, sqlConnection, dbCommand);
                    using (var dataReader = dbCommand.ExecuteReader(CommandBehavior.SingleResult))
                    {
                        Dictionary<string, int> columns = null;
                        while (dataReader.Read())
                        {
                            columns = GetDataReaderColumns(dataReader, columns, (GenericPredicate)null);
                            var entity = (T)EntityMap(entityType, entityType, dataReader, columns, null, null, true);
                            var enumString = propertyDeclarator.GetValue(entity).ToString();
                            if (!Enum.IsDefined(enumType, enumString)) continue;
                            var enumValue = (E)Enum.Parse(enumType, enumString, true);
                            if (enumEntityPairs.ContainsKey(enumValue)) continue;
                            enumEntityPairs.Add(enumValue, entity);
                        }
                    }
                }
                catch (Exception exception)
                {
                    HandleException(exception, dbCommand);
                }
                finally
                {
                    if (session == null || session.TransactionScope == null)
                    {
                        sqlConnection.Close();
                    }
                }
            }
            return enumEntityPairs;
        }

        protected static Profile ProfileGetId<T>(T entity) where T : class
        {
            Profile profile = null;
            if (entity != null)
            {
                var typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(entity.GetType());
                if (typeDeclarator.Identity != null)
                {
                    var value = typeDeclarator.Identity.GetValue(entity);
                    typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(ClientStatic.Profile);
                    if (typeDeclarator.Identity != null)
                    {
                        profile = new Profile();
                        typeDeclarator.Identity.SetValue(profile, value);
                    }
                }
            }
            return profile;
        }

        protected static Property PropertyGet(IDataReader dataReader)
        {
            var property = new Property();
            var typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(ClientStatic.Property);
            foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
            {
                var propertyValue = GetDataReaderValue(propertyDeclarator.DatabaseColumn, dataReader, GetDataReaderColumns(dataReader, null, (GenericPredicate)null), null);
                if (propertyValue == null) continue;
                SetPropertyDeclaratorValue(propertyValue, propertyDeclarator, property);
            }
            return property;
        }

        protected GenericOutput<Profile> ProfileMap<T>(PermissionType permissionType, T entity, Profile profile) where T : class
        {
            var genericOutput = new GenericOutput<Profile>
            {
                PermissionType = permissionType,
                Pager = new Pager(),
                Entities = new List<Profile>()
            };
            var genericInput = new GenericInput<Profile, GenericPredicate>
            {
                PermissionType = permissionType,
                Entity = profile
            };
            var sqlCommand = new SqlCommand
            {
                CommandText = Kernel.Instance.TypeDeclaratorManager.Get(ClientStatic.Profile).DatabaseMapping.StoredProcedure,
                CommandType = CommandType.StoredProcedure
            };
            sqlCommand.Parameters.AddWithValue("@genericInput", EngineStatic.PortableXmlSerialize(genericInput));
            var number = new SqlParameter
            {
                ParameterName = "@number",
                Direction = ParameterDirection.Output,
                DbType = DbType.Int32
            };
            sqlCommand.Parameters.Add(number);
            var type = entity.GetType();
            var typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(type);
            var session = Kernel.Instance.SessionManager.SessionRead();
            var sqlConnection = session == null || session.TransactionScope == null ? new SqlConnection(ConnectionString) : session.SqlConnections[ConnectionString];
            try
            {
                SetDbCommand(session, sqlConnection, sqlCommand);
                using (var dataReader = sqlCommand.ExecuteReader())
                {
                    while (dataReader.Read())
                    {
                        foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
                        {
                            if (propertyDeclarator.ProfileProperty == null ||
                                string.IsNullOrEmpty(propertyDeclarator.ProfileProperty.ProfileCode)) continue;
                            var property = PropertyGet(dataReader);
                            if (string.Compare(propertyDeclarator.ProfileProperty.ProfileCode, property.Code, StringComparison.OrdinalIgnoreCase) != 0 ||
                                string.IsNullOrEmpty(property.Value)) continue;
                            var propertyInfo = type.GetProperty(propertyDeclarator.PropertyInfo.Name);
                            if (propertyInfo == null) continue;
                            if (propertyDeclarator.PropertyInfo.PropertyType == ClientStatic.StructureGuid ||
                                propertyDeclarator.PropertyInfo.PropertyType == ClientStatic.NullableGuid)
                            {
                                propertyInfo.SetValue(entity, new Guid(property.Value), null);
                            }
                            else if (propertyDeclarator.PropertyInfo.PropertyType.IsGenericType &&
                                propertyDeclarator.PropertyInfo.PropertyType.GetGenericTypeDefinition() == ClientStatic.Nullable)
                            {
                                var underlyingType = Nullable.GetUnderlyingType(propertyDeclarator.PropertyInfo.PropertyType);
                                if (underlyingType != null)
                                {
                                    propertyInfo.SetValue(entity, Convert.ChangeType(property.Value, underlyingType, CultureInfo.InvariantCulture), null);
                                }
                            }
                            else if (propertyDeclarator.PropertyInfo.PropertyType.IsArray ||
                                propertyDeclarator.IsGenericEntity ||
                                propertyDeclarator.IsGenericPredicate)
                            {
                                propertyDeclarator.SetValue(entity, EngineStatic.XmlDeserialize(property.Value, propertyDeclarator.PropertyInfo.PropertyType));
                            }
                            else
                            {
                                propertyInfo.SetValue(entity, Convert.ChangeType(property.Value, propertyDeclarator.PropertyInfo.PropertyType, CultureInfo.InvariantCulture), null);
                            }
                            break;
                        }
                    }
                }
                genericOutput.Pager.Number = (int)number.Value;
            }
            catch (Exception exception)
            {
                HandleException(exception, sqlCommand);
            }
            finally
            {
                if (session == null || session.TransactionScope == null)
                {
                    sqlConnection.Close();
                }
            }
            return genericOutput;
        }

        protected T ProfileGet<T>(T entity) where T : GenericEntity
        {
            if (entity != null &&
                Kernel.Instance.GenericCache.Get(new Profile {Id = entity.GetId()}) == null)
            {
                var profile = ProfileGetId(entity);
                if (profile != null)
                {
                    ProfileMap(PermissionType.ProfileRead, entity, profile);
                    Kernel.Instance.GenericCache.Add(profile);
                }
            }
            return entity;
        }

        protected static bool ProfileRemove<T>(T entity) where T : GenericEntity
        {
            var removed = false;
            if (entity != null)
            {
                removed = Kernel.Instance.GenericCache.Remove(new Profile {Id = entity.GetId()});
            }
            return removed;
        }

        protected bool ProfileDelete<T>(T entity) where T : class
        {
            var deleted = false;
            var profile = ProfileGetId(entity);
            if (profile != null)
            {
                deleted = ProfileMap(PermissionType.ProfileDelete, entity, profile).Pager.Number > 0;
                Kernel.Instance.GenericCache.Remove(profile);
            }
            return deleted;
        }

        protected T ProfileSave<T>(T entityTo, T entityFrom) where T : GenericEntity
        {
            if (entityTo != null &&
                entityFrom != null)
            {
                entityFrom.SetId(entityTo.GetId());
                ProfileSave(entityFrom);
                Kernel.Instance.TypeDeclaratorManager.ProfilePropertyMap(entityTo, entityFrom, false);
            }
            return entityTo;
        }

        protected T ProfileSave<T>(T entity) where T : class
        {
            var profile = ProfileGetId(entity);
            if (profile != null)
            {
                profile.Properties = new List<Property>();
                var typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(entity.GetType());
                foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
                {
                    if (propertyDeclarator.ProfileProperty == null ||
                        string.IsNullOrEmpty(propertyDeclarator.ProfileProperty.ProfileCode)) continue;
                    var property = new Property
                    {
                        Code = propertyDeclarator.ProfileProperty.ProfileCode,
                        Value = MapParameter(propertyDeclarator.GetValue(entity), propertyDeclarator.PropertyInfo).ToString()
                    };
                    Kernel.Instance.TypeDeclaratorManager.GetUndefinedProperties(property, "Code");
                    profile.Properties.Add(property);
                }
                ProfileMap(PermissionType.ProfileUpdate, entity, profile);
                Kernel.Instance.GenericCache.Add(profile);
            }
            return entity;
        }
        
        #endregion Methods

        #endregion Protected Members

        #region Public Members

        #region Methods

        public void SqlCommandDelay<T>(Token token, GenericOutput<T> genericOutput, string sqlCommandText, Dictionary<string, object> sqlParameters, string connectionString) where T : GenericEntity
        {
            var parameters = new List<string>();
            foreach (var keyValue in sqlParameters)
            {
                parameters.Add(string.Format("{0} : {1}", keyValue.Key, keyValue.Value));
            }
            var log = new Log
            {
                Application = token.Application,
                Account = token.Account,
                TokenId = token.Id,
                CreatedOn = DateTimeOffset.Now,
                LogActionType = LogActionType.SqlCommandDelay,
                Parameters = new []
                {
                    sqlCommandText,
                    string.Join(Constants.COMMA.ToString(), parameters),
                    (genericOutput.QueryEnd - genericOutput.QueryStart).ToString(),
                    genericOutput.QueryStart.ToString(),
                    genericOutput.QueryEnd.ToString(),
                    token.Emplacement.Code,
                    token.Application.Code,
                    token.ClientHost,
                    token.Account == null ? string.Empty : token.Account.User.Code,
                    token.RequestHost,
                    token.RequestPort.ToString()
                }
            };
            var customAttribute = ClientStatic.GetCustomAttribute<FieldCategory>(ClientStatic.LogActionType.GetField(LogActionType.SqlCommandDelay.ToString()), true);
            log.Comment = string.Format(customAttribute.Description, Array.ConvertAll(log.Parameters, converter => (object)converter));
            var sqlCommand = new SqlCommand
            {
                CommandText = Kernel.Instance.TypeDeclaratorManager.Get(ClientStatic.Log).DatabaseMapping.StoredProcedure,
                CommandType = CommandType.StoredProcedure
            };
            sqlCommand.Parameters.AddWithValue("@genericInput", EngineStatic.PortableXmlSerialize(new GenericInput<Log, LogPredicate>
            {
                Entity = log,
                PermissionType = PermissionType.LogCreate
            }));
            var number = new SqlParameter
            {
                ParameterName = "@number",
                Direction = ParameterDirection.Output,
                DbType = DbType.Int32
            };
            sqlCommand.Parameters.Add(number);
            ExecuteNonQuery(sqlCommand, connectionString);
        }

        #endregion Methods

        #endregion Public Members
    }
}