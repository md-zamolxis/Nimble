#region Usings

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Reflection;

#endregion Usings

namespace Nimble.Business.Library.Model
{
    [DataContract]
    public enum SortType
    {
        [EnumMember]
        [FieldCategory(Name = "ascending")]
        Ascending,
        [EnumMember]
        [FieldCategory(Name = "descending")]
        Descending
    }

    [DataContract]
    public class Sort : IComparable<Sort>
    {
        #region Public

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public int Index { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public SortType SortType { get; set; }

        #endregion Properties

        #region Methods

        public int CompareTo(Sort sort)
        {
            return Index.CompareTo(sort.Index);
        }

        public override string ToString()
        {
            return string.Format("{0} {1}", Name, (SortType == SortType.Ascending) ? "ASC" : "DESC");
        }

        #endregion Methods

        #endregion Public
    }

    [DataContract]
    public class Pager
    {
        #region Private Members

        #region Properties

        private int? pages;

        #endregion Properties

        #endregion Private Members

        #region Public

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public short? Index { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public short? Size { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public short StartLag { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public int Count { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public int Number { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public int? Pages 
        { 
            get
            {
                if (Size.HasValue && 
                    Size.Value > 0)
                {
                    pages = Number/Size.Value + Math.Sign(Number%Size.Value);
                }
                else
                {
                    pages = null;
                }
                return pages;
            }
            set
            {
                pages = value;
            } 
        }

        #endregion Properties

        #endregion Public
    }

    [DataContract]
    public class Criteria<T>
    {
        #region Public

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public bool IsExcluded { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool IsNull { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public T Value { get; set; }

        #endregion Properties

        #region Methods

        public Criteria(){}

        public Criteria(T value)
        {
            Value = value;
        }

        #endregion Methods

        #endregion Public
    }

    [DataContract]
    public abstract class GenericPredicate
    {
        #region Private Members

        #region Properties

        private string order;

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public bool IsExcluded { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Pager Pager { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<string> Columns { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool PassColumns { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Hierarchy Hierarchy { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Order
        {
            get
            {
                order = null;
                if (Sorts != null &&
                    Sorts.Count > 0)
                {
                    var indexes = new List<int>();
                    for (var index = 0; index < Sorts.Count; index++)
                    {
                        if (Sorts[index] == null ||
                            Sorts[index].Name == null)
                        {
                            indexes.Add(index);
                            continue;
                        }
                        if (string.IsNullOrEmpty(Sorts[index].Name.Trim()))
                        {
                            indexes.Add(index);
                        }
                    }
                    foreach (var index in indexes)
                    {
                        Sorts.RemoveAt(index);
                    }
                    Sorts.Sort();
                    order = " ORDER BY " + string.Join(Constants.COMMA.ToString(), Sorts.Select(sort => sort.ToString()).ToArray());
                }
                return order;
            }
            set
            {
                order = value;
            }
        }

        [DataMember(EmitDefaultValue = false)]
        public List<Sort> Sorts { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<string> Group { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string GroupTop { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string GroupBottom { get; set; }

        #endregion Properties

        #region Methods

        public void Grouping(IEnumerable<PropertyDeclarator> propertyDeclarators)
        {
            var groupTop = new List<string>();
            var groupBottom = new List<string>();
            foreach (var propertyDeclarator in propertyDeclarators)
            {
                if (propertyDeclarator.DatabaseColumn == null ||
                    !propertyDeclarator.DatabaseColumn.AllowGrouping ||
                    string.IsNullOrEmpty(propertyDeclarator.DatabaseColumn.Name)) continue;
                var alias = string.IsNullOrEmpty(propertyDeclarator.DatabaseColumn.Alias) ? propertyDeclarator.DatabaseColumn.Name : propertyDeclarator.DatabaseColumn.Alias;
                var field = "NULL";
                var names = propertyDeclarator.DatabaseColumn.Name.Split(Constants.SEMICOLON);
                for (var index = 0; index < names.Length; index++)
                {
                    var name = names[index];
                    if (Group == null || 
                        Group.FirstOrDefault(item => item.Equals(name, StringComparison.OrdinalIgnoreCase)) == null) continue;
                    field = name;
                    if (!string.IsNullOrEmpty(propertyDeclarator.DatabaseColumn.Format))
                    {
                        var formats = propertyDeclarator.DatabaseColumn.Format.Split(Constants.SEMICOLON);
                        if (index < formats.Length)
                        {
                            var format = formats[index];
                            if (!string.IsNullOrEmpty(format))
                            {
                                field = string.Format(format, field);
                            }
                        }
                    }
                    groupBottom.Add(field);
                    break;
                }
                groupTop.Add(string.Format(" {0} {1}", field, alias));
            }
            var comma = Constants.COMMA.ToString();
            GroupTop = string.Join(comma, groupTop.ToArray());
            GroupBottom = string.Join(comma, groupBottom.ToArray());
        }

        public List<string> HandleColumns()
        {
            return PassColumns ? Columns : null;
        }

        #endregion Methods

        #endregion Public Members
    }
}