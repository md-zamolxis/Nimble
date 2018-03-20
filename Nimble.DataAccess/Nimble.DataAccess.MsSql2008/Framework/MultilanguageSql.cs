#region Using

using System.Data;
using System.Data.SqlClient;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Engine.Common;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class MultilanguageSql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly MultilanguageSql instance = new MultilanguageSql(Kernel.Instance.ServerConfiguration.GenericDatabase);

        #endregion Properties

        #region Methods

        private MultilanguageSql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static MultilanguageSql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public MultilanguageSql() { }

        #region Culture

        public Culture CultureCreate(Culture culture)
        {
            return EntityAction(PermissionType.CultureCreate, culture).Entity;
        }

        public Culture CultureRead(Culture culture)
        {
            return Kernel.Instance.GenericCache.GetEntity(culture) ?? EntityAction(PermissionType.CultureRead, culture).Entity;
        }

        public Culture CultureUpdate(Culture culture)
        {
            return EntityAction(PermissionType.CultureUpdate, culture).Entity;
        }

        public bool CultureDelete(Culture culture)
        {
            return EntityDelete(PermissionType.CultureDelete, culture);
        }

        public GenericOutput<Culture> CultureSearch(GenericInput<Culture, CulturePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.CultureSearch;
            return EntityAction(genericInput);
        }

        #endregion Culture

        #region Resource

        public Resource ResourceCreate(Resource resource)
        {
            return EntityAction(PermissionType.ResourceCreate, resource).Entity;
        }

        public Resource ResourceRead(Resource resource)
        {
            return Kernel.Instance.GenericCache.GetEntity(resource) ?? EntityAction(PermissionType.ResourceRead, resource).Entity;
        }

        public Resource ResourceUpdate(Resource resource)
        {
            return EntityAction(PermissionType.ResourceUpdate, resource).Entity;
        }

        public bool ResourceDelete(Resource resource)
        {
            return EntityDelete(PermissionType.ResourceDelete, resource);
        }

        public GenericOutput<Resource> ResourceSearch(GenericInput<Resource, ResourcePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.ResourceSearch;
            return EntityAction(genericInput);
        }

        public Resource ResourceSave(Resource resource)
        {
            return EntityAction(PermissionType.ResourceSave, resource).Entity;
        }

        #endregion Resource

        #region Translation

        public Translation TranslationCreate(Translation translation)
        {
            return EntityAction(PermissionType.TranslationCreate, translation).Entity;
        }

        public Translation TranslationRead(Translation translation)
        {
            return Kernel.Instance.GenericCache.GetEntity(translation) ?? EntityAction(PermissionType.TranslationRead, translation).Entity;
        }

        public Translation TranslationUpdate(Translation translation)
        {
            return EntityAction(PermissionType.TranslationUpdate, translation).Entity;
        }

        public bool TranslationDelete(Translation translation)
        {
            return EntityDelete(PermissionType.TranslationDelete, translation);
        }

        public GenericOutput<Translation> TranslationSearch(GenericInput<Translation, TranslationPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.TranslationSearch;
            return EntityAction(genericInput);
        }

        #endregion Translation

        public void Copy(Emplacement emplacement, Application application)
        {
            var sqlCommand = new SqlCommand
            {
                CommandText = "[Multilanguage].[Copy]",
                CommandType = CommandType.StoredProcedure
            };
            sqlCommand.Parameters.Add(new SqlParameter
            {
                ParameterName = "@emplacement",
                Direction = ParameterDirection.Input,
                Value = EngineStatic.PortableXmlSerialize(emplacement)
            });
            sqlCommand.Parameters.Add(new SqlParameter
            {
                ParameterName = "@application",
                Direction = ParameterDirection.Input,
                Value = EngineStatic.PortableXmlSerialize(application)
            });
            ExecuteRowCount(sqlCommand);
        }

        #endregion Methods

        #endregion Public Members
    }
}
