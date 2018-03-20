#region Using

using System.ServiceModel;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Geolocation;

#endregion Using

namespace Nimble.Server.Iis.Framework.Interface
{
    [ServiceContract]
    public interface IGeolocation
    {
        #region Source

        [OperationContract]
        Source SourceCreate(Source source);

        [OperationContract]
        Source SourceRead(Source source);

        [OperationContract]
        Source SourceUpdate(Source source);

        [OperationContract]
        bool SourceDelete(Source source);

        [OperationContract]
        GenericOutput<Source> SourceSearch(SourcePredicate sourcePredicate);

        [OperationContract]
        Source SourceLoad(Source source);

        [OperationContract]
        Source SourceApprove(Source source);

        #endregion Source

        #region Location

        [OperationContract]
        GenericOutput<Location> LocationSearch(LocationPredicate locationPredicate);

        #endregion Location

        #region Block

        [OperationContract]
        Block BlockRead(Block block);

        [OperationContract]
        GenericOutput<Block> BlockSearch(BlockPredicate blockPredicate);

        #endregion Block
    }
}