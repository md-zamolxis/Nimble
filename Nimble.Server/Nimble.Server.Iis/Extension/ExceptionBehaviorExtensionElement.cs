#region Using

using System;
using System.ServiceModel.Configuration;

#endregion Using

namespace Nimble.Server.Iis.Extension
{
    public class ExceptionBehaviorExtensionElement : BehaviorExtensionElement
    {
        #region Protected Members

        #region Methods

        protected override object CreateBehavior()
        {
            return new ExceptionServiceBehavior();
        }

        #endregion Methods

        #endregion Protected Members

        #region Public Members

        #region Properties

        public override Type BehaviorType
        {
            get
            {
                return typeof(ExceptionServiceBehavior);
            }
        }

        #endregion Properties

        #endregion Public Members
    }
}
