#region Using

using System.Collections.Generic;
using System.Data.SqlClient;
using System.ServiceModel;
using System.Transactions;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Business.Engine.Core
{
    public class Session : IExtension<OperationContext>
    {
        #region Public Members

        #region Properties

        public Token Token { get; set; }

        public TransactionScope TransactionScope { get; set; }

        public Dictionary<string, SqlConnection> SqlConnections { get; set; }

        #endregion Properties

        #region Methods

        public Session()
        {
            Token = new Token
            {
                Code = string.Empty
            };
        }

        public void Attach(OperationContext owner) { }

        public void Detach(OperationContext owner) { }

        public bool HasTransactionScope()
        {
            return TransactionScope != null;
        }

        #endregion Methods

        #endregion Public Members
    }
}