#region Using

using System;
using System.Collections.Generic;
using System.ServiceModel.Activation;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Common : ICommon
    {
        #region Joint

        public bool HandleException(FaultExceptionDetail faultExceptionDetail)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).HandleException(faultExceptionDetail);
        }

        public Tuple<List<Culture>, List<Resource>, List<Translation>, Token> Multilanguage(CulturePredicate culturePredicate, ResourcePredicate resourcePredicate, TranslationPredicate translationPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).Multilanguage(culturePredicate, resourcePredicate, translationPredicate);
        }

        public Translation Translation(Resource resource)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).Translation(resource);
        }

        public string Translate(string code, string category, params object[] parameters)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).Translate(code, category, parameters);
        }

        public Token Login(string userCode, string userPassword)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).Login(userCode, userPassword);
        }

        public bool Logout()
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).Logout();
        }

        public string IpInfoRead(string ip)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).IpInfoRead(ip, true);
        }

        public Token SignIn(string referenceId)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).SignIn(referenceId);
        }

        public FaultExceptionDetail ResetPasswordSend(string email)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).ResetPasswordSend(email);
        }

        public User ResetPasswordCheck(string key, string value)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).ResetPasswordCheck(key, value);
        }

        public User ResetPasswordProceed(string key, string value, string password)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).ResetPasswordProceed(key, value, password);
        }

        public User ResetPasswordUnlock(string key, string value, string password, bool isEncrypted)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).ResetPasswordProceed(key, value, password, isEncrypted);
        }

        public Person SignCheckPerson(string userCode)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).SignCheckPerson(userCode);
        }

        public Person SignUpPerson(Person person)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).SignUpPerson(person);
        }

        public Employee SignCheckOrganisation(string organisationCode, string userCode)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).SignCheckOrganisation(organisationCode, userCode);
        }

        public Employee SignUpOrganisation(Employee employee)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).SignUpOrganisation(employee);
        }

        public Token SignInOrganisation(Organisation organisation)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).SignInOrganisation(organisation);
        }

        #endregion Joint

        #region Token

        public Token TokenRead()
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).TokenRead();
        }

        public Token TokenUpdate(Token token)
        {
            return CommonLogic.InstanceCheck(PermissionType.TokenUpdate).TokenUpdate(token);
        }

        public bool TokenDelete(TokenPredicate tokenPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.TokenDelete).TokenDelete(tokenPredicate);
        }

        public List<Token> TokenSearch(TokenPredicate tokenPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.TokenSearch).TokenSearch(tokenPredicate);
        }

        public bool TokenHasPermissions(PermissionType[] permissionTypes)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).TokenHasPermissions(permissionTypes);
        }

        public bool AccountHasPermissions(Account account, PermissionType[] permissionTypes)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).AccountHasPermissions(account, permissionTypes);
        }

        public bool TokenIsExpired()
        {
            return CommonLogic.TokenIsExpired();
        }

        #endregion Tokens

        #region Lock

        public bool LockDelete(Token token)
        {
            return CommonLogic.InstanceCheck(PermissionType.LockDelete).LockDelete(token);
        }

        public List<Token> LockSearch(TokenPredicate tokenPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.LockSearch).LockSearch(tokenPredicate);
        }

        #endregion Lock

        #region Preset

        public Preset PresetCreate(Preset preset)
        {
            return CommonLogic.InstanceCheck(PermissionType.PresetCreate).PresetCreate(preset);
        }

        public Preset PresetRead(Preset preset)
        {
            return CommonLogic.InstanceCheck(PermissionType.PresetRead).PresetRead(preset);
        }

        public Preset PresetUpdate(Preset preset)
        {
            return CommonLogic.InstanceCheck(PermissionType.PresetUpdate).PresetUpdate(preset);
        }

        public bool PresetDelete(Preset preset)
        {
            return CommonLogic.InstanceCheck(PermissionType.PresetDelete).PresetDelete(preset);
        }

        public GenericOutput<Preset> PresetSearch(PresetPredicate presetPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).PresetSearch(presetPredicate);
        }

        #endregion Preset

        #region Split

        public Split SplitCreate(Split split)
        {
            return CommonLogic.InstanceCheck(PermissionType.SplitCreate).SplitCreate(split);
        }

        public Split SplitRead(Split split)
        {
            return CommonLogic.InstanceCheck(PermissionType.SplitRead).SplitRead(split);
        }

        public Split SplitUpdate(Split split)
        {
            return CommonLogic.InstanceCheck(PermissionType.SplitUpdate).SplitUpdate(split);
        }

        public bool SplitDelete(Split split)
        {
            return CommonLogic.InstanceCheck(PermissionType.SplitDelete).SplitDelete(split);
        }

        public GenericOutput<Split> SplitSearch(SplitPredicate splitPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.SplitSearch).SplitSearch(splitPredicate);
        }

        #endregion Split

        #region Group

        public Group GroupCreate(Group group)
        {
            return CommonLogic.InstanceCheck(PermissionType.GroupCreate).GroupCreate(group);
        }

        public Group GroupRead(Group group)
        {
            return CommonLogic.InstanceCheck(PermissionType.GroupRead).GroupRead(group);
        }

        public Group GroupUpdate(Group group)
        {
            return CommonLogic.InstanceCheck(PermissionType.GroupUpdate).GroupUpdate(group);
        }

        public bool GroupDelete(Group group)
        {
            return CommonLogic.InstanceCheck(PermissionType.GroupDelete).GroupDelete(group);
        }

        public GenericOutput<Group> GroupSearch(GroupPredicate groupPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.GroupSearch).GroupSearch(groupPredicate);
        }

        #endregion Group

        #region Bond

        public Bond BondRead(Bond bond)
        {
            return CommonLogic.InstanceCheck(PermissionType.BondRead).BondRead(bond);
        }

        public GenericOutput<Bond> BondSearch(BondPredicate bondPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.BondSearch).BondSearch(bondPredicate);

        }

        #endregion Bond

        #region Filestream

        public Filestream FilestreamRead(Filestream filestream)
        {
            return CommonLogic.InstanceCheck(PermissionType.Public).FilestreamRead(filestream);
        }

        public GenericOutput<Filestream> FilestreamSearch(FilestreamPredicate filestreamPredicate)
        {
            return CommonLogic.InstanceCheck(PermissionType.FilestreamSearch).FilestreamSearch(filestreamPredicate);
        }

        #endregion Filestream
    }
}