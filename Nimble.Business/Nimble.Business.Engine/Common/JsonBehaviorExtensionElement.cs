#region Using

using System;
using System.ServiceModel.Configuration;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class JsonBehaviorExtensionElement : BehaviorExtensionElement
    {
        #region Protected Members

        #region Methods

        protected override object CreateBehavior()
        {
            return new JsonWebHttpBehavior();
        }

        #endregion Methods

        #endregion Protected Members

        #region Public Members

        #region Properties

        public override Type BehaviorType
        {
            get
            {
                return typeof(JsonWebHttpBehavior);
            }
        }

        #endregion Properties

        #endregion Public Members
    }
}
