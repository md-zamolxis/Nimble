#region Using

using System;
using System.Collections.Generic;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Multicurrency;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.Business.Logic.Framework
{
    public class MulticurrencyLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly MulticurrencyLogic instance = new MulticurrencyLogic();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static MulticurrencyLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static MulticurrencyLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        #region Currency

        public Currency CurrencyCreate(Currency currency)
        {
            EntityPropertiesCheck(
                currency,
                "Code");
            currency.SetDefaults();
            currency.Organisation = OrganisationCheck(currency.Organisation);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Multicurrency
                });
                currency = MulticurrencySql.Instance.CurrencyCreate(currency);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return currency;
        }

        public Currency CurrencyRead(Currency currency)
        {
            EntityInstanceCheck(currency);
            currency = MulticurrencySql.Instance.CurrencyRead(currency);
            if (GenericEntity.HasValue(currency))
            {
                OrganisationCheck(currency.Organisation);
            }
            return currency;
        }

        public Currency CurrencyUpdate(Currency currency)
        {
            EntityPropertiesCheck(
                currency,
                "Code");
            currency.SetDefaults();
            CurrencyRead(currency);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Multicurrency
                });
                currency = MulticurrencySql.Instance.CurrencyUpdate(currency);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return currency;
        }

        public bool CurrencyDelete(Currency currency)
        {
            var deleted = false;
            CurrencyRead(currency);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Multicurrency
                });
                deleted = MulticurrencySql.Instance.CurrencyDelete(currency);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<Currency> CurrencySearch(CurrencyPredicate currencyPredicate)
        {
            return MulticurrencySql.Instance.CurrencySearch(GenericInputCheck<Currency, CurrencyPredicate>(currencyPredicate));
        }

        #endregion Currency

        #region Trade

        public Trade TradeCreate(Trade trade)
        {
            EntityInstanceCheck(trade);
            trade.SetDefaults();
            trade.From = Kernel.Instance.ServerConfiguration.MinDate;
            trade.To = Kernel.Instance.ServerConfiguration.MaxDate;
            trade.Organisation = OrganisationCheck(trade.Organisation);
            if (trade.AppliedOn.HasValue)
            {
                trade.AppliedOn = trade.AppliedOn.Value.DateOffset();
            }
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Multicurrency
                });
                trade = MulticurrencySql.Instance.TradeCreate(trade);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return trade;
        }

        public Trade TradeRead(Trade trade)
        {
            EntityInstanceCheck(trade);
            trade = MulticurrencySql.Instance.TradeRead(trade);
            if (GenericEntity.HasValue(trade))
            {
                OrganisationCheck(trade.Organisation);
            }
            return trade;
        }

        public Trade TradeUpdate(Trade trade)
        {
            EntityPropertiesCheck(
                trade,
                "Code");
            trade.SetDefaults();
            TradeRead(trade);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Multicurrency
                });
                trade = MulticurrencySql.Instance.TradeUpdate(trade);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return trade;
        }

        public bool TradeDelete(Trade trade)
        {
            var deleted = false;
            TradeRead(trade);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Multicurrency
                });
                deleted = MulticurrencySql.Instance.TradeDelete(trade);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<Trade> TradeSearch(TradePredicate tradePredicate)
        {
            return MulticurrencySql.Instance.TradeSearch(GenericInputCheck<Trade, TradePredicate>(tradePredicate));
        }

        #endregion Trade

        #region Rate

        public Rate RateCreate(Rate rate)
        {
            EntityPropertiesCheck(
                rate,
                "Trade",
                "CurrencyFrom",
                "CurrencyTo",
                "Value");
            rate.Trade.Organisation = OrganisationCheck(rate.Trade.Organisation);
            return MulticurrencySql.Instance.RateCreate(rate);
        }

        public Rate RateRead(Rate rate)
        {
            EntityInstanceCheck(rate);
            rate = MulticurrencySql.Instance.RateRead(rate);
            if (GenericEntity.HasValue(rate))
            {
                OrganisationCheck(rate.Trade.Organisation);
            }
            return rate;
        }

        public Rate RateUpdate(Rate rate)
        {
            EntityPropertiesCheck(
                rate,
                "Trade",
                "CurrencyFrom",
                "CurrencyTo",
                "Value");
            RateRead(rate);
            return MulticurrencySql.Instance.RateUpdate(rate);
        }

        public GenericOutput<Rate> RateSearch(RatePredicate ratePredicate)
        {
            return MulticurrencySql.Instance.RateSearch(GenericInputCheck<Rate, RatePredicate>(ratePredicate));
        }

        #endregion Rate

        #endregion Methods

        #endregion Public Members
    }
}