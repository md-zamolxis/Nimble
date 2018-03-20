#region Using

using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class CommonSql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly CommonSql instance = new CommonSql(Kernel.Instance.ServerConfiguration.GenericDatabase);

        #endregion Properties

        #region Methods

        private CommonSql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static CommonSql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public CommonSql() { }

        #region Preset

        public Preset PresetCreate(Preset preset)
        {
            return EntityAction(PermissionType.PresetCreate, preset).Entity;
        }

        public Preset PresetRead(Preset preset)
        {
            return EntityAction(PermissionType.PresetRead, preset).Entity;
        }

        public Preset PresetUpdate(Preset preset)
        {
            return EntityAction(PermissionType.PresetUpdate, preset).Entity;
        }

        public bool PresetDelete(Preset preset)
        {
            return EntityDelete(PermissionType.PresetDelete, preset);
        }

        public GenericOutput<Preset> PresetSearch(GenericInput<Preset, PresetPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PresetSearch;
            return EntityAction(genericInput);
        }

        #endregion Preset

        #region Split

        public Split SplitCreate(Split split)
        {
            return EntityAction(PermissionType.SplitCreate, split).Entity;
        }

        public Split SplitRead(Split split)
        {
            return EntityAction(PermissionType.SplitRead, split).Entity;
        }

        public Split SplitUpdate(Split split)
        {
            return EntityAction(PermissionType.SplitUpdate, split).Entity;
        }

        public bool SplitDelete(Split split)
        {
            return EntityDelete(PermissionType.SplitDelete, split);
        }

        public GenericOutput<Split> SplitSearch(GenericInput<Split, SplitPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.SplitSearch;
            return EntityAction(genericInput);
        }

        #endregion Split

        #region Group

        public Group GroupCreate(Group group)
        {
            return EntityAction(PermissionType.GroupCreate, group).Entity;
        }

        public Group GroupRead(Group group)
        {
            return EntityAction(PermissionType.GroupRead, group).Entity;
        }

        public Group GroupUpdate(Group group)
        {
            return EntityAction(PermissionType.GroupUpdate, group).Entity;
        }

        public bool GroupDelete(Group group)
        {
            return EntityDelete(PermissionType.GroupDelete, group);
        }

        public GenericOutput<Group> GroupSearch(GenericInput<Group, GroupPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.GroupSearch;
            return EntityAction(genericInput);
        }

        #endregion Group

        #region Bond

        public Bond BondRead(Bond bond)
        {
            return EntityAction(PermissionType.BondRead, bond).Entity;
        }

        public GenericOutput<Bond> BondSearch(GenericInput<Bond, BondPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BondSearch;
            return EntityAction(genericInput);
        }

        #endregion Bond

        #region Hierarchy

        public bool HierarchySave(Hierarchy hierarchy)
        {
            return EntityAction(PermissionType.HierarchySave, hierarchy).Pager.Number > 0;
        }

        public bool HierarchyRemove(Hierarchy hierarchy)
        {
            return EntityAction(PermissionType.HierarchyRemove, hierarchy).Pager.Number > 0;
        }

        #endregion Hierarchy

        #region Filestream

        public Filestream FilestreamRead(Filestream filestream)
        {
            return EntityAction(PermissionType.FilestreamRead, filestream).Entity;
        }

        public GenericOutput<Filestream> FilestreamSearch(GenericInput<Filestream, FilestreamPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.FilestreamSearch;
            return EntityAction(genericInput);
        }

        public void FilestreamSync(GenericInput<Filestream, FilestreamPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.FilestreamSync;
            EntityAction(genericInput);
        }

        public bool FilestreamRemove(GenericInput<Filestream, FilestreamPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.FilestreamRemove;
            return EntityAction(genericInput).Pager.Number > 0;
        }

        #endregion Filestream

        #endregion Methods

        #endregion Public Members
    }
}
