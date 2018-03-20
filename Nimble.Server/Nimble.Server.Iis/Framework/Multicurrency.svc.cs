#region Using

using System.ServiceModel.Activation;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Multicurrency;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Multicurrency : IMulticurrency
    {
        #region Currency

        public Currency CurrencyCreate(Currency currency)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.CurrencyCreate).CurrencyCreate(currency);
        }

        public Currency CurrencyRead(Currency currency)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.CurrencyRead).CurrencyRead(currency);
        }

        public Currency CurrencyUpdate(Currency currency)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.CurrencyUpdate).CurrencyUpdate(currency);
        }

        public bool CurrencyDelete(Currency currency)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.CurrencyDelete).CurrencyDelete(currency);
        }

        public GenericOutput<Currency> CurrencySearch(CurrencyPredicate currencyPredicate)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.CurrencySearch).CurrencySearch(currencyPredicate);
        }

        #endregion Currency

        #region Trade

        public Trade TradeCreate(Trade trade)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.TradeCreate).TradeCreate(trade);
        }

        public Trade TradeRead(Trade trade)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.TradeRead).TradeRead(trade);
        }

        public Trade TradeUpdate(Trade trade)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.TradeUpdate).TradeUpdate(trade);
        }

        public bool TradeDelete(Trade trade)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.TradeDelete).TradeDelete(trade);
        }

        public GenericOutput<Trade> TradeSearch(TradePredicate tradePredicate)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.TradeSearch).TradeSearch(tradePredicate);
        }

        #endregion Trade

        #region Rate

        public Rate RateCreate(Rate rate)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.RateCreate).RateCreate(rate);
        }

        public Rate RateRead(Rate rate)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.RateRead).RateRead(rate);
        }

        public Rate RateUpdate(Rate rate)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.RateUpdate).RateUpdate(rate);
        }

        public GenericOutput<Rate> RateSearch(RatePredicate ratePredicate)
        {
            return MulticurrencyLogic.InstanceCheck(PermissionType.RateSearch).RateSearch(ratePredicate);
        }

        #endregion Rate
    }
}
