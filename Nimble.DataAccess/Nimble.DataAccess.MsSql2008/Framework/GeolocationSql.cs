#region Using

using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Geolocation;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class GeolocationSql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly GeolocationSql instance = new GeolocationSql(Kernel.Instance.ServerConfiguration.GeolocationDatabase);

        #endregion Properties

        #region Methods

        private GeolocationSql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static GeolocationSql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public GeolocationSql() { }

        #region Source

        public Source SourceCreate(Source source)
        {
            return EntityAction(PermissionType.SourceCreate, source).Entity;
        }

        public Source SourceRead(Source source)
        {
            return EntityAction(PermissionType.SourceRead, source).Entity;
        }

        public Source SourceUpdate(Source source)
        {
            return EntityAction(PermissionType.SourceUpdate, source).Entity;
        }

        public bool SourceDelete(Source source)
        {
            return EntityDelete(PermissionType.SourceDelete, source);
        }

        public GenericOutput<Source> SourceSearch(GenericInput<Source, SourcePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.SourceSearch;
            return EntityAction(genericInput);
        }

        public Source SourceLoad(Source source)
        {
            return EntityAction(PermissionType.SourceLoad, source).Entity;
        }

        public int SourceApprove(Source source)
        {
            return EntityAction(PermissionType.SourceApprove, source).Pager.Number;
        }

        #endregion Source

        #region Portion

        public Portion PortionCreate(Portion portion)
        {
            return EntityAction(PermissionType.PortionCreate, portion).Entity;
        }

        public Portion PortionRead(Portion portion)
        {
            return EntityAction(PermissionType.PortionRead, portion).Entity;
        }

        public Portion PortionUpdate(Portion portion)
        {
            return EntityAction(PermissionType.PortionUpdate, portion).Entity;
        }

        #endregion Portion

        #region Location

        public GenericOutput<Location> LocationSearch(GenericInput<Location, LocationPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.LocationSearch;
            return EntityAction(genericInput);
        }

        #endregion Location

        #region Block

        public Block BlockRead(Block block)
        {
            return EntityAction(PermissionType.BlockRead, block).Entity;
        }

        public GenericOutput<Block> BlockSearch(GenericInput<Block, BlockPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BlockSearch;
            return EntityAction(genericInput);
        }

        #endregion Block

        #endregion Methods

        #endregion Public Members
    }
}
