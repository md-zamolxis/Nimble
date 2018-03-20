#region Using

using System.ServiceModel.Activation;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Geolocation;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Geolocation : IGeolocation
    {
        #region Source

        public Source SourceCreate(Source source)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.SourceCreate).SourceCreate(source);
        }

        public Source SourceRead(Source source)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.SourceRead).SourceRead(source);
        }

        public Source SourceUpdate(Source source)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.SourceUpdate).SourceUpdate(source);
        }

        public bool SourceDelete(Source source)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.SourceDelete).SourceDelete(source);
        }

        public GenericOutput<Source> SourceSearch(SourcePredicate sourcePredicate)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.SourceSearch).SourceSearch(sourcePredicate);
        }

        public Source SourceLoad(Source source)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.SourceLoad).SourceLoad(source);
        }

        public Source SourceApprove(Source source)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.SourceApprove).SourceApprove(source);
        }

        #endregion Source

        #region Location

        public GenericOutput<Location> LocationSearch(LocationPredicate locationPredicate)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.LocationSearch).LocationSearch(locationPredicate);
        }

        #endregion Location

        #region Block

        public Block BlockRead(Block block)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.BlockRead).BlockRead(block);
        }

        public GenericOutput<Block> BlockSearch(BlockPredicate blockPredicate)
        {
            return GeolocationLogic.InstanceCheck(PermissionType.BlockSearch).BlockSearch(blockPredicate);
        }

        #endregion Block
    }
}