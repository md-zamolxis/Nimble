#region Using

using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Multicurrency;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class MulticurrencySql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly MulticurrencySql instance = new MulticurrencySql(Kernel.Instance.ServerConfiguration.GenericDatabase);

        #endregion Properties

        #region Methods

        private MulticurrencySql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static MulticurrencySql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public MulticurrencySql() { }

        #region Currency

        public Currency CurrencyCreate(Currency currency)
        {
            return EntityAction(PermissionType.CurrencyCreate, currency).Entity;
        }

        public Currency CurrencyRead(Currency currency)
        {
            return EntityAction(PermissionType.CurrencyRead, currency).Entity;
        }

        public Currency CurrencyUpdate(Currency currency)
        {
            return EntityAction(PermissionType.CurrencyUpdate, currency).Entity;
        }

        public bool CurrencyDelete(Currency currency)
        {
            return EntityDelete(PermissionType.CurrencyDelete, currency);
        }

        public GenericOutput<Currency> CurrencySearch(GenericInput<Currency, CurrencyPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.CurrencySearch;
            return EntityAction(genericInput);
        }

        #endregion Currency

        #region Trade

        public Trade TradeCreate(Trade trade)
        {
            return EntityAction(PermissionType.TradeCreate, trade).Entity;
        }

        public Trade TradeRead(Trade trade)
        {
            return EntityAction(PermissionType.TradeRead, trade).Entity;
        }

        public Trade TradeUpdate(Trade trade)
        {
            return EntityAction(PermissionType.TradeUpdate, trade).Entity;
        }

        public bool TradeDelete(Trade trade)
        {
            return EntityDelete(PermissionType.TradeDelete, trade);
        }

        public GenericOutput<Trade> TradeSearch(GenericInput<Trade, TradePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.TradeSearch;
            return EntityAction(genericInput);
        }

        #endregion Trade

        #region Rate

        public Rate RateCreate(Rate rate)
        {
            return EntityAction(PermissionType.RateCreate, rate).Entity;
        }

        public Rate RateRead(Rate rate)
        {
            return EntityAction(PermissionType.RateRead, rate).Entity;
        }

        public Rate RateUpdate(Rate rate)
        {
            return EntityAction(PermissionType.RateUpdate, rate).Entity;
        }

        public GenericOutput<Rate> RateSearch(GenericInput<Rate, RatePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.RateSearch;
            return EntityAction(genericInput);
        }

        #endregion Rate

        #endregion Methods

        #endregion Public Members
    }
}
