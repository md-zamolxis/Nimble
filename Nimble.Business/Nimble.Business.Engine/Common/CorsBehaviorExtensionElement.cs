#region Using

using System;
using System.ServiceModel.Configuration;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class CorsBehaviorExtensionElement : BehaviorExtensionElement
    {
        #region Protected Members

        #region Methods

        protected override object CreateBehavior()
        {
            return new CorsWebHttpBehavior();
        }

        #endregion Methods

        #endregion Protected Members

        #region Public Members

        #region Properties

        public override Type BehaviorType
        {
            get
            {
                return typeof(CorsWebHttpBehavior);
            }
        }

        #endregion Properties

        #endregion Public Members
    }
}
