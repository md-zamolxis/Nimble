#region Using

using System;
using System.Globalization;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.Business.Logic.Framework
{
    public class MultilanguageLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly MultilanguageLogic instance = new MultilanguageLogic();

        #endregion Properties

        #region Methods

        private static void CheckTranslationSense(Translation translation)
        {
            var index = 0;
            while (index >= 0)
            {
                var parameter = Constants.LEFT_BRACE + index.ToString(CultureInfo.InvariantCulture) + Constants.RIGHT_BRACE;
                if (translation.Resource.Code.Contains(parameter))
                {
                    if (translation.Sense.Contains(parameter))
                    {
                        index++;
                    }
                    else
                    {
                        ThrowException("Cannot save translation - orders of parameters are different for code and sense.");
                    }
                }
                else
                {
                    index = -1;
                }
            }
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static MultilanguageLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static MultilanguageLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        #region Culture

        public Culture CultureCreate(Culture culture)
        {
            EntityPropertiesCheck(
                culture,
                "Code",
                "Name");
            culture.Emplacement = EmplacementCheck(culture.Emplacement);
            return MultilanguageSql.Instance.CultureCreate(culture);
        }

        public Culture CultureRead(Culture culture)
        {
            EntityInstanceCheck(culture);
            culture = MultilanguageSql.Instance.CultureRead(culture);
            if (GenericEntity.HasValue(culture))
            {
                EmplacementCheck(culture.Emplacement);
            }
            return culture;
        }

        public Culture CultureUpdate(Culture culture)
        {
            EntityPropertiesCheck(
                culture,
                "Code",
                "Name");
            CultureRead(culture);
            return MultilanguageSql.Instance.CultureUpdate(culture);
        }

        public bool CultureDelete(Culture culture)
        {
            CultureRead(culture);
            return MultilanguageSql.Instance.CultureDelete(culture);
        }

        public GenericOutput<Culture> CultureSearch(CulturePredicate culturePredicate)
        {
            return MultilanguageSql.Instance.CultureSearch(GenericInputCheck<Culture, CulturePredicate>(culturePredicate));
        }

        #endregion Culture

        #region Resource

        public Resource ResourceCreate(Resource resource)
        {
            EntityPropertiesCheck(
                resource,
                "Code",
                "Category");
            EntityValidate(resource);
            resource.SetDefaults();
            resource.Emplacement = EmplacementCheck(resource.Emplacement);
            resource.Application = ApplicationCheck(resource.Application);
            return MultilanguageSql.Instance.ResourceCreate(resource);
        }

        public Resource ResourceRead(Resource resource)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            EntityPropertiesCheck(
                resource,
                "Code",
                "Category");
            EntityValidate(resource);
            resource.SetDefaults();
            resource.Emplacement = EmplacementCheck(resource.Emplacement);
            resource.Application = ApplicationCheck(resource.Application);
            var resourceEntity = MultilanguageSql.Instance.ResourceRead(resource);
            if (!session.HasTransactionScope() &&
                resource.Application.IsAdministrative)
            {
                if (!GenericEntity.HasValue(resourceEntity))
                {
                    resourceEntity = MultilanguageSql.Instance.ResourceCreate(resource);
                }
                else if (resourceEntity.LastUsedOn.HasValue &&
                         resourceEntity.LastUsedOn.Value.AddDays(Kernel.Instance.ServerConfiguration.ResourceLastUsedLatencyDays) < session.Token.LastUsedOn)
                {
                    resourceEntity.LastUsedOn = session.Token.LastUsedOn;
                    resourceEntity = MultilanguageSql.Instance.ResourceSave(resourceEntity);
                }
            }
            else if (!GenericEntity.HasValue(resourceEntity))
            {
                resourceEntity = resource;
            }
            return resourceEntity;
        }

        public Resource ResourceUpdate(Resource resource)
        {
            EntityPropertiesCheck(
                resource,
                "Code",
                "Category");
            EntityValidate(resource);
            resource.LastUsedOn = DateTimeOffset.Now;
            ResourceRead(resource);
            return MultilanguageSql.Instance.ResourceUpdate(resource);
        }

        public bool ResourceDelete(Resource resource)
        {
            ResourceRead(resource);
            return MultilanguageSql.Instance.ResourceDelete(resource);
        }

        public GenericOutput<Resource> ResourceSearch(ResourcePredicate resourcePredicate)
        {
            return MultilanguageSql.Instance.ResourceSearch(GenericInputCheck<Resource, ResourcePredicate>(resourcePredicate));
        }

        #endregion Resource

        #region Translation

        public Translation TranslationCreate(Translation translation)
        {
            EntityPropertiesCheck(
                translation,
                "Sense");
            translation.Resource = MultilanguageSql.Instance.ResourceRead(translation.Resource);
            EntityPropertiesCheck(
                translation,
                "Resource");
            translation.Resource.Emplacement = EmplacementCheck(translation.Resource.Emplacement);
            translation.Resource.Application = ApplicationCheck(translation.Resource.Application);
            translation.Culture = MultilanguageSql.Instance.CultureRead(translation.Culture);
            EntityPropertiesCheck(
                translation,
                "Culture");
            translation.Culture.Emplacement = EmplacementCheck(translation.Culture.Emplacement);
            CheckTranslationSense(translation);
            return MultilanguageSql.Instance.TranslationCreate(translation);
        }

        public Translation TranslationRead(Translation translation)
        {
            EntityInstanceCheck(translation);
            translation = MultilanguageSql.Instance.TranslationRead(translation);
            if (GenericEntity.HasValue(translation))
            {
                EmplacementCheck(translation.Resource.Emplacement);
                ApplicationCheck(translation.Resource.Application);
                EmplacementCheck(translation.Culture.Emplacement);
            }
            return translation;
        }

        public Translation TranslationUpdate(Translation translation)
        {
            EntityPropertiesCheck(
                translation,
                "Sense");
            TranslationRead(translation);
            CheckTranslationSense(translation);
            return MultilanguageSql.Instance.TranslationUpdate(translation);
        }

        public bool TranslationDelete(Translation translation)
        {
            TranslationRead(translation);
            return MultilanguageSql.Instance.TranslationDelete(translation);
        }

        public GenericOutput<Translation> TranslationSearch(TranslationPredicate translationPredicate)
        {
            return MultilanguageSql.Instance.TranslationSearch(GenericInputCheck<Translation, TranslationPredicate>(translationPredicate));
        }

        #endregion Translations

        #endregion Methods

        #endregion Public Members
    }
}