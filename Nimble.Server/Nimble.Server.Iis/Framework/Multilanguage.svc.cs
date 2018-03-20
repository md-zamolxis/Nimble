#region Using

using System.ServiceModel.Activation;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Multilanguage : IMultilanguage
    {
        #region Culture

        public Culture CultureCreate(Culture culture)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.CultureCreate).CultureCreate(culture);
        }

        public Culture CultureRead(Culture culture)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.Public).CultureRead(culture);
        }

        public Culture CultureUpdate(Culture culture)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.CultureUpdate).CultureUpdate(culture);
        }

        public bool CultureDelete(Culture culture)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.CultureDelete).CultureDelete(culture);
        }

        public GenericOutput<Culture> CultureSearch(CulturePredicate culturePredicate)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.Public).CultureSearch(culturePredicate);
        }

        #endregion Culture

        #region Resource

        public Resource ResourceCreate(Resource entity)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.ResourceCreate).ResourceCreate(entity);
        }

        public Resource ResourceRead(Resource entity)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.Public).ResourceRead(entity);
        }

        public Resource ResourceUpdate(Resource entity)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.ResourceUpdate).ResourceUpdate(entity);
        }

        public bool ResourceDelete(Resource entity)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.ResourceDelete).ResourceDelete(entity);
        }

        public GenericOutput<Resource> ResourceSearch(ResourcePredicate resourcePredicate)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.Public).ResourceSearch(resourcePredicate);
        }

        #endregion Resource

        #region Translation

        public Translation TranslationCreate(Translation translation)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.TranslationCreate).TranslationCreate(translation);
        }

        public Translation TranslationRead(Translation translation)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.Public).TranslationRead(translation);
        }

        public Translation TranslationUpdate(Translation translation)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.TranslationUpdate).TranslationUpdate(translation);
        }

        public bool TranslationDelete(Translation translation)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.TranslationDelete).TranslationDelete(translation);
        }

        public GenericOutput<Translation> TranslationSearch(TranslationPredicate translationPredicate)
        {
            return MultilanguageLogic.InstanceCheck(PermissionType.Public).TranslationSearch(translationPredicate);
        }

        #endregion Translation
    }
}