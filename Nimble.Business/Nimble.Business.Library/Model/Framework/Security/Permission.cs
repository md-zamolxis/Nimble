#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Security
{
    [DataContract]
    public enum PermissionType
    {
        [EnumMember]
        Public,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTokens, Description = "Enable access to method that updates token.")]
        TokenUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTokens, Description = "Enable access to method that searches tokens by predicate.")]
        TokenSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTokens, Description = "Enable access to method that deletes tokens by predicate.")]
        TokenDelete,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLocks, Description = "Enable access to method that updates lock.")]
        LockUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLocks, Description = "Enable access to method that deletes lock by token.")]
        LockDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLocks, Description = "Enable access to method that searches locks by predicate.")]
        LockSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageProfiles, Description = "Enable access to method that reads profile by id or natural keys.")]
        ProfileRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageProfiles, Description = "Enable access to method that updates profile.")]
        ProfileUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageProfiles, Description = "Enable access to method that deletes profile by id or natural keys.")]
        ProfileDelete,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePresets, Description = "Enable access to method that creates preset.")]
        PresetCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePresets, Description = "Enable access to method that reads preset by id or natural keys.")]
        PresetRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePresets, Description = "Enable access to method that updates preset.")]
        PresetUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePresets, Description = "Enable access to method that deletes preset by id or natural keys.")]
        PresetDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePresets, Description = "Enable access to method that searches presets by predicate.")]
        PresetSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSplits, Description = "Enable access to method that creates split.")]
        SplitCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSplits, Description = "Enable access to method that reads split by id or natural keys.")]
        SplitRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSplits, Description = "Enable access to method that updates split.")]
        SplitUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSplits, Description = "Enable access to method that deletes split.")]
        SplitDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSplits, Description = "Enable access to method that searches splits by predicate.")]
        SplitSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageGroups, Description = "Enable access to method that creates group.")]
        GroupCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageGroups, Description = "Enable access to method that reads group by id or natural keys.")]
        GroupRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageGroups, Description = "Enable access to method that updates group.")]
        GroupUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageGroups, Description = "Enable access to method that deletes group.")]
        GroupDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageGroups, Description = "Enable access to method that searches groups by predicate.")]
        GroupSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBonds, Description = "Enable access to method that reads branch bond by id or natural keys.")]
        BondRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBonds, Description = "Enable access to method that searches bonds by predicate.")]
        BondSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageHierarchies, Description = "Enable access to method that saves hierarchy.")]
        HierarchySave,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageHierarchies, Description = "Enable access to method that removes hierarchy.")]
        HierarchyRemove,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageFilestreams, Description = "Enable access to method that reads filestream by id or natural keys.")]
        FilestreamRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageFilestreams, Description = "Enable access to method that searches filestreams by predicate.")]
        FilestreamSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageFilestreams, Description = "Enable access to method that syncs filestreams.")]
        FilestreamSync,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageFilestreams, Description = "Enable access to method that removes filestreams.")]
        FilestreamRemove,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmplacements, Description = "Enable access to method that creates emplacement.")]
        EmplacementCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmplacements, Description = "Enable access to method that reads emplacement by id or natural keys.")]
        EmplacementRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmplacements, Description = "Enable access to method that updates emplacement.")]
        EmplacementUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmplacements, Description = "Enable access to method that deletes emplacement by id or natural keys.")]
        EmplacementDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmplacements, Description = "Enable access to method that searches emplacements by predicate.")]
        EmplacementSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageApplications, Description = "Enable access to method that creates application.")]
        ApplicationCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageApplications, Description = "Enable access to method that reads application by id or natural keys.")]
        ApplicationRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageApplications, Description = "Enable access to method that updates application.")]
        ApplicationUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageApplications, Description = "Enable access to method that deletes application by id or natural keys.")]
        ApplicationDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageApplications, Description = "Enable access to method that searches applications by predicate.")]
        ApplicationSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageUsers, Description = "Enable access to method that creates user.")]
        UserCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageUsers, Description = "Enable access to method that reads user by id or natural keys.")]
        UserRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageUsers, Description = "Enable access to method that updates user.")]
        UserUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageUsers, Description = "Enable access to method that deletes user by id or natural keys.")]
        UserDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageUsers, Description = "Enable access to method that searches users by predicate.")]
        UserSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageUsers, Description = "Enable access to method that changes user password.")]
        UserChange,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageAccounts, Description = "Enable access to method that creates account.")]
        AccountCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageAccounts, Description = "Enable access to method that reads account by id or natural keys.")]
        AccountRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageAccounts, Description = "Enable access to method that updates account.")]
        AccountUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageAccounts, Description = "Enable access to method that deletes account by id or natural keys.")]
        AccountDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageAccounts, Description = "Enable access to method that searches accounts by predicate.")]
        AccountSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRoles, Description = "Enable access to method that creates role.")]
        RoleCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRoles, Description = "Enable access to method that reads role by id or natural keys.")]
        RoleRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRoles, Description = "Enable access to method that updates role.")]
        RoleUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRoles, Description = "Enable access to method that deletes role by id or natural keys.")]
        RoleDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRoles, Description = "Enable access to method that searches roles by predicate.")]
        RoleSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePermissions, Description = "Enable access to method that creates permission.")]
        PermissionCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePermissions, Description = "Enable access to method that reads permission by id or natural keys.")]
        PermissionRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePermissions, Description = "Enable access to method that updates permission.")]
        PermissionUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePermissions, Description = "Enable access to method that deletes permission by id or natural keys.")]
        PermissionDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePermissions, Description = "Enable access to method that searches permissions by predicate.")]
        PermissionSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLogs, Description = "Enable access to method that creates log.")]
        LogCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLogs, Description = "Enable access to method that reads log by id.")]
        LogRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLogs, Description = "Enable access to method that searches logs by predicate.")]
        LogSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCultures, Description = "Enable access to method that creates culture.")]
        CultureCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCultures, Description = "Enable access to method that reads culture by id or natural keys.")]
        CultureRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCultures, Description = "Enable access to method that updates culture.")]
        CultureUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCultures, Description = "Enable access to method that deletes culture by id or natural keys.")]
        CultureDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCultures, Description = "Enable access to method that searches cultures by predicate.")]
        CultureSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageResources, Description = "Enable access to method that creates resource.")]
        ResourceCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageResources, Description = "Enable access to method that reads resource by id or natural keys.")]
        ResourceRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageResources, Description = "Enable access to method that updates resource.")]
        ResourceUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageResources, Description = "Enable access to method that deletes resource by id or natural keys.")]
        ResourceDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageResources, Description = "Enable access to method that searches resources by predicate.")]
        ResourceSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageResources, Description = "Enable access to method that saves resource.")]
        ResourceSave,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTranslations, Description = "Enable access to method that creates translation.")]
        TranslationCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTranslations, Description = "Enable access to method that reads translation by id or natural keys.")]
        TranslationRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTranslations, Description = "Enable access to method that updates translation.")]
        TranslationUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTranslations, Description = "Enable access to method that deletes translation by id or natural keys.")]
        TranslationDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTranslations, Description = "Enable access to method that searches translations by predicate.")]
        TranslationSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCurrencies, Description = "Enable access to method that creates currency.")]
        CurrencyCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCurrencies, Description = "Enable access to method that reads currency by id or natural keys.")]
        CurrencyRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCurrencies, Description = "Enable access to method that updates currency.")]
        CurrencyUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCurrencies, Description = "Enable access to method that deletes currency by id or natural keys.")]
        CurrencyDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageCurrencies, Description = "Enable access to method that searches currencies by predicate.")]
        CurrencySearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTrades, Description = "Enable access to method that creates trade.")]
        TradeCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTrades, Description = "Enable access to method that reads trade by id or natural keys.")]
        TradeRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTrades, Description = "Enable access to method that updates trade.")]
        TradeUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTrades, Description = "Enable access to method that deletes trade by id or natural keys.")]
        TradeDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTrades, Description = "Enable access to method that searches trades by predicate.")]
        TradeSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRates, Description = "Enable access to method that creates rate.")]
        RateCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRates, Description = "Enable access to method that reads rate by id or natural keys.")]
        RateRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRates, Description = "Enable access to method that updates rate.")]
        RateUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRates, Description = "Enable access to method that searches rates by predicate.")]
        RateSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBackups, Description = "Enable access to method that creates backup.")]
        BackupCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBackups, Description = "Enable access to method that reads backup by id or natural keys.")]
        BackupRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBackups, Description = "Enable access to method that searches backups by predicate.")]
        BackupSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBackups, Description = "Enable access to method that deletes backups by predicate.")]
        BackupDelete,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBatches, Description = "Enable access to method that creates batch.")]
        BatchCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBatches, Description = "Enable access to method that reads batch by id or natural keys.")]
        BatchRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBatches, Description = "Enable access to method that searches batchs by predicate.")]
        BatchSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBatches, Description = "Enable access to method that deletes batches by predicate.")]
        BatchDelete,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageOperations, Description = "Enable access to method that searches operations by predicate.")]
        OperationSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSources, Description = "Enable access to method that creates source.")]
        SourceCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSources, Description = "Enable access to method that reads source by id or natural keys.")]
        SourceRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSources, Description = "Enable access to method that updates source.")]
        SourceUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSources, Description = "Enable access to method that deletes source by id or natural keys.")]
        SourceDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSources, Description = "Enable access to method that searches sources by predicate.")]
        SourceSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSources, Description = "Enable access to method that loads source by id or natural keys.")]
        SourceLoad,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSources, Description = "Enable access to method that approves source.")]
        SourceApprove,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePortions, Description = "Enable access to method that creates portion.")]
        PortionCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePortions, Description = "Enable access to method that reads portion by id or natural keys.")]
        PortionRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePortions, Description = "Enable access to method that updates portion.")]
        PortionUpdate,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLocations, Description = "Enable access to method that searches locations by predicate.")]
        LocationSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBlocks, Description = "Enable access to method that reads block by natural keys.")]
        BlockRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBlocks, Description = "Enable access to method that searches blocks by predicate.")]
        BlockSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePersons, Description = "Enable access to method that creates person.")]
        PersonCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePersons, Description = "Enable access to method that reads person by id or natural keys.")]
        PersonRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePersons, Description = "Enable access to method that updates person.")]
        PersonUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePersons, Description = "Enable access to method that deletes person by id or natural keys.")]
        PersonDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePersons, Description = "Enable access to method that searches persons by predicate.")]
        PersonSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMarks, Description = "Enable access to method that creates mark.")]
        MarkCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMarks, Description = "Enable access to method that reads mark by id or natural keys.")]
        MarkRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMarks, Description = "Enable access to method that updates mark.")]
        MarkUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMarks, Description = "Enable access to method that deletes mark by id or natural keys.")]
        MarkDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMarks, Description = "Enable access to method that searches marks by predicate.")]
        MarkSearch,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMarks, Description = "Enable access to method that searches mark resumes by predicate.")]
        MarkResumeSearch,


        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageOrganisations, Description = "Enable access to method that creates organisation.")]
        OrganisationCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageOrganisations, Description = "Enable access to method that reads organisation by id or natural keys.")]
        OrganisationRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageOrganisations, Description = "Enable access to method that updates organisation.")]
        OrganisationUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageOrganisations, Description = "Enable access to method that deletes organisation by id or natural keys.")]
        OrganisationDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageOrganisations, Description = "Enable access to method that searches organisations by predicate.")]
        OrganisationSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchSplits, Description = "Enable access to method that creates branch split.")]
        BranchSplitCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchSplits, Description = "Enable access to method that reads branch split by id or natural keys.")]
        BranchSplitRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchSplits, Description = "Enable access to method that updates branch split.")]
        BranchSplitUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchSplits, Description = "Enable access to method that deletes branch split.")]
        BranchSplitDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchSplits, Description = "Enable access to method that searches branch splits by predicate.")]
        BranchSplitSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchGroups, Description = "Enable access to method that creates branch group.")]
        BranchGroupCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchGroups, Description = "Enable access to method that reads branch group by id or natural keys.")]
        BranchGroupRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchGroups, Description = "Enable access to method that updates branch group.")]
        BranchGroupUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchGroups, Description = "Enable access to method that deletes branch group.")]
        BranchGroupDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchGroups, Description = "Enable access to method that searches branch groups by predicate.")]
        BranchGroupSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchBonds, Description = "Enable access to method that reads branch bond by id or natural keys.")]
        BranchBondRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranchBonds, Description = "Enable access to method that searches branch bonds by predicate.")]
        BranchBondSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranches, Description = "Enable access to method that creates branch.")]
        BranchCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranches, Description = "Enable access to method that reads branch by id or natural keys.")]
        BranchRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranches, Description = "Enable access to method that updates branch.")]
        BranchUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranches, Description = "Enable access to method that deletes branch by id or natural keys.")]
        BranchDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageBranches, Description = "Enable access to method that searches branches by predicate.")]
        BranchSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRanges, Description = "Enable access to method that creates range.")]
        RangeCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRanges, Description = "Enable access to method that reads range by id or natural keys.")]
        RangeRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRanges, Description = "Enable access to method that updates range.")]
        RangeUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRanges, Description = "Enable access to method that deletes range by id or natural keys.")]
        RangeDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageRanges, Description = "Enable access to method that searches ranges by predicate.")]
        RangeSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmployees, Description = "Enable access to method that creates employee.")]
        EmployeeCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmployees, Description = "Enable access to method that reads employee by id or natural keys.")]
        EmployeeRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmployees, Description = "Enable access to method that updates employee.")]
        EmployeeUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmployees, Description = "Enable access to method that deletes employee by id or natural keys.")]
        EmployeeDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageEmployees, Description = "Enable access to method that searches employees by predicate.")]
        EmployeeSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostSplits, Description = "Enable access to method that creates post split.")]
        PostSplitCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostSplits, Description = "Enable access to method that reads post split by id or natural keys.")]
        PostSplitRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostSplits, Description = "Enable access to method that updates post split.")]
        PostSplitUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostSplits, Description = "Enable access to method that deletes post split.")]
        PostSplitDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostSplits, Description = "Enable access to method that searches post splits by predicate.")]
        PostSplitSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostGroups, Description = "Enable access to method that creates post group.")]
        PostGroupCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostGroups, Description = "Enable access to method that reads post group by id or natural keys.")]
        PostGroupRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostGroups, Description = "Enable access to method that updates post group.")]
        PostGroupUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostGroups, Description = "Enable access to method that deletes post group.")]
        PostGroupDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostGroups, Description = "Enable access to method that searches post groups by predicate.")]
        PostGroupSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostBonds, Description = "Enable access to method that reads post bond by id or natural keys.")]
        PostBondRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePostBonds, Description = "Enable access to method that searches post bonds by predicate.")]
        PostBondSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePosts, Description = "Enable access to method that creates posts.")]
        PostCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePosts, Description = "Enable access to method that reads posts.")]
        PostRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePosts, Description = "Enable access to method that updates posts.")]
        PostUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePosts, Description = "Enable access to method that deletes posts.")]
        PostDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePosts, Description = "Enable access to method that searches posts by predicate.")]
        PostSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLayouts, Description = "Enable access to method that creates layouts.")]
        LayoutCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLayouts, Description = "Enable access to method that reads layouts.")]
        LayoutRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLayouts, Description = "Enable access to method that updates layouts.")]
        LayoutUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLayouts, Description = "Enable access to method that deletes layouts.")]
        LayoutDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageLayouts, Description = "Enable access to method that searches layouts by predicate.")]
        LayoutSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePublishers, Description = "Enable access to method that creates publishers.")]
        PublisherCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePublishers, Description = "Enable access to method that reads publishers.")]
        PublisherRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePublishers, Description = "Enable access to method that updates publishers.")]
        PublisherUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePublishers, Description = "Enable access to method that deletes publishers.")]
        PublisherDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManagePublishers, Description = "Enable access to method that searches publishers by predicate.")]
        PublisherSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSubscribers, Description = "Enable access to method that creates subscribers.")]
        SubscriberCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSubscribers, Description = "Enable access to method that reads subscribers.")]
        SubscriberRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSubscribers, Description = "Enable access to method that updates subscribers.")]
        SubscriberUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSubscribers, Description = "Enable access to method that deletes subscribers.")]
        SubscriberDelete,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageSubscribers, Description = "Enable access to method that searches subscribers by predicate.")]
        SubscriberSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMessages, Description = "Enable access to method that creates messages.")]
        MessageCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMessages, Description = "Enable access to method that reads messages.")]
        MessageRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageMessages, Description = "Enable access to method that searches messages by predicate.")]
        MessageSearch,

        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTraces, Description = "Enable access to method that creates traces.")]
        TraceCreate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTraces, Description = "Enable access to method that reads traces.")]
        TraceRead,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTraces, Description = "Enable access to method that updates traces.")]
        TraceUpdate,
        [EnumMember]
        [FieldCategory(FieldCategoryType = FieldCategoryType.ManageTraces, Description = "Enable access to method that searches traces by predicate.")]
        TraceSearch
    }

    [DataContract]
    public class PermissionPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Categories { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Permission>> Permissions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public ApplicationPredicate ApplicationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public RolePredicate RolePredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public AccountPredicate AccountPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Permission")]
    [DatabaseMapping(StoredProcedure = "[Security].[Permission.Action]")]
    public class Permission : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PermissionId", IsIdentity = true)]
        [DisplayName("Permission id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Permission application")]
        [UndefinedValues(ConstantType.NullReference)]
        public Application Application { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PermissionCode")]
        [DisplayName("Permission code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrim)]
        [PropertyTypes(typeof(PermissionType))]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PermissionCategory")]
        [DisplayName("Permission category")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrim)]
        public string Category { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PermissionDescription")]
        [DisplayName("Permission description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PermissionVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Application) &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Application.GetIdCode() + Code.ToUpper());
            }
            return keys;
        }

        public PermissionType GetPermissionType()
        {
            var type = ClientStatic.PermissionType;
            return Enum.IsDefined(type, code) ? (PermissionType)Enum.Parse(type, code, true) : PermissionType.Public;
        }

        #endregion Methods

        #endregion Public Members
    }
}