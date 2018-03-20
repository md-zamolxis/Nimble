#region Using

using System.ServiceModel;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Multicurrency;

#endregion Using

namespace Nimble.Server.Iis.Framework.Interface
{
    [ServiceContract]
    public interface IMulticurrency
    {
        #region Currency

        [OperationContract]
        Currency CurrencyCreate(Currency currency);

        [OperationContract]
        Currency CurrencyRead(Currency currency);

        [OperationContract]
        Currency CurrencyUpdate(Currency currency);

        [OperationContract]
        bool CurrencyDelete(Currency currency);

        [OperationContract]
        GenericOutput<Currency> CurrencySearch(CurrencyPredicate currencyPredicate);

        #endregion Currency

        #region Trade

        [OperationContract]
        Trade TradeCreate(Trade trade);

        [OperationContract]
        Trade TradeRead(Trade trade);

        [OperationContract]
        Trade TradeUpdate(Trade trade);

        [OperationContract]
        bool TradeDelete(Trade trade);

        [OperationContract]
        GenericOutput<Trade> TradeSearch(TradePredicate tradePredicate);

        #endregion Trade

        #region Rate

        [OperationContract]
        Rate RateCreate(Rate rate);

        [OperationContract]
        Rate RateRead(Rate rate);

        [OperationContract]
        Rate RateUpdate(Rate rate);

        [OperationContract]
        GenericOutput<Rate> RateSearch(RatePredicate ratePredicate);

        #endregion Rate
    }
}