#region Using

using System;
using System.Runtime.Serialization;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [DataContract]
    public enum FieldCategoryType
    {
        [EnumMember]
        None,
        [EnumMember]
        [FieldCategory(Name = "Manage tokens")]
        ManageTokens,
        [EnumMember]
        [FieldCategory(Name = "Manage locks")]
        ManageLocks,
        [EnumMember]
        [FieldCategory(Name = "Manage profiles")]
        ManageProfiles,
        [EnumMember]
        [FieldCategory(Name = "Manage presets")]
        ManagePresets,
        [EnumMember]
        [FieldCategory(Name = "Manage splits")]
        ManageSplits,
        [EnumMember]
        [FieldCategory(Name = "Manage groups")]
        ManageGroups,
        [EnumMember]
        [FieldCategory(Name = "Manage bonds")]
        ManageBonds,
        [EnumMember]
        [FieldCategory(Name = "Manage hierarchies")]
        ManageHierarchies,
        [EnumMember]
        [FieldCategory(Name = "Manage filestreams")]
        ManageFilestreams,
        [EnumMember]
        [FieldCategory(Name = "Manage emplacements")]
        ManageEmplacements,
        [EnumMember]
        [FieldCategory(Name = "Manage applications")]
        ManageApplications,
        [EnumMember]
        [FieldCategory(Name = "Manage users")]
        ManageUsers,
        [EnumMember]
        [FieldCategory(Name = "Manage accounts")]
        ManageAccounts,
        [EnumMember]
        [FieldCategory(Name = "Manage roles")]
        ManageRoles,
        [EnumMember]
        [FieldCategory(Name = "Manage permissions")]
        ManagePermissions,
        [EnumMember]
        [FieldCategory(Name = "Manage logs")]
        ManageLogs,
        [EnumMember]
        [FieldCategory(Name = "Manage cultures")]
        ManageCultures,
        [EnumMember]
        [FieldCategory(Name = "Manage resources")]
        ManageResources,
        [EnumMember]
        [FieldCategory(Name = "Manage translations")]
        ManageTranslations,
        [EnumMember]
        [FieldCategory(Name = "Manage currencies")]
        ManageCurrencies,
        [EnumMember]
        [FieldCategory(Name = "Manage trades")]
        ManageTrades,
        [EnumMember]
        [FieldCategory(Name = "Manage rates")]
        ManageRates,
        [EnumMember]
        [FieldCategory(Name = "Manage backups")]
        ManageBackups,
        [EnumMember]
        [FieldCategory(Name = "Manage batches")]
        ManageBatches,
        [EnumMember]
        [FieldCategory(Name = "Manage operations")]
        ManageOperations,
        [EnumMember]
        [FieldCategory(Name = "Manage sources")]
        ManageSources,
        [EnumMember]
        [FieldCategory(Name = "Manage portions")]
        ManagePortions,
        [EnumMember]
        [FieldCategory(Name = "Manage locations")]
        ManageLocations,
        [EnumMember]
        [FieldCategory(Name = "Manage blocks")]
        ManageBlocks,
        [EnumMember]
        [FieldCategory(Name = "Manage persons")]
        ManagePersons,
        [EnumMember]
        [FieldCategory(Name = "Manage marks")]
        ManageMarks,
        [EnumMember]
        [FieldCategory(Name = "Manage organisations")]
        ManageOrganisations,
        [EnumMember]
        [FieldCategory(Name = "Manage branch splits")]
        ManageBranchSplits,
        [EnumMember]
        [FieldCategory(Name = "Manage branch groups")]
        ManageBranchGroups,
        [EnumMember]
        [FieldCategory(Name = "Manage branch bonds")]
        ManageBranchBonds,
        [EnumMember]
        [FieldCategory(Name = "Manage branches")]
        ManageBranches,
        [EnumMember]
        [FieldCategory(Name = "Manage ranges")]
        ManageRanges,
        [EnumMember]
        [FieldCategory(Name = "Manage employees")]
        ManageEmployees,
        [EnumMember]
        [FieldCategory(Name = "Manage post splits")]
        ManagePostSplits,
        [EnumMember]
        [FieldCategory(Name = "Manage post groups")]
        ManagePostGroups,
        [EnumMember]
        [FieldCategory(Name = "Manage post bonds")]
        ManagePostBonds,
        [EnumMember]
        [FieldCategory(Name = "Manage posts")]
        ManagePosts,
        [EnumMember]
        [FieldCategory(Name = "Manage layouts")]
        ManageLayouts,
        [EnumMember]
        [FieldCategory(Name = "Manage publishers")]
        ManagePublishers,
        [EnumMember]
        [FieldCategory(Name = "Manage subscribers")]
        ManageSubscribers,
        [EnumMember]
        [FieldCategory(Name = "Manage messages")]
        ManageMessages,
        [EnumMember]
        [FieldCategory(Name = "Manage traces")]
        ManageTraces
    }

    [AttributeUsage(AttributeTargets.Field)]
    public sealed class FieldCategory : Attribute
    {
        #region Public Members

        #region Properties

        public string Name { get; set; }

        public FieldCategoryType FieldCategoryType { get; set; }

        public string Description { get; set; }

        public Type Type { get; set; }

        public string Key { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}