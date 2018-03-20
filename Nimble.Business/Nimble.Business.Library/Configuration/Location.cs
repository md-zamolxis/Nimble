#region Usings

#endregion Usings

namespace Nimble.Business.Library.Configuration
{
    public class LocationConfiguration
    {
        #region Public Members

        #region Properties

        public string Path { get; set; }

        public LocationSystemWebConfiguration LocationSystemWebConfiguration { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class LocationSystemWebConfiguration
    {
        #region Public Members

        #region Properties

        public LocationSystemWebAuthorizationConfiguration LocationSystemWebAuthorizationConfiguration { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class LocationSystemWebAuthorizationConfiguration
    {
        #region Public Members

        #region Properties

        public LocationSystemWebAuthorizationAllowConfiguration LocationSystemWebAuthorizationAllowConfiguration { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class LocationSystemWebAuthorizationAllowConfiguration
    {
        #region Public Members

        #region Properties

        public string Users { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}
