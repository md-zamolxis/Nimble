#region Using

using System;
using System.Collections.Generic;
using System.Linq;
using Hangfire;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataTransport;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.Business.Logic.Framework
{
    public class OwnerLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly OwnerLogic instance = new OwnerLogic();

        #endregion Properties

        #region Methods

        private static Organisation OrganisationRead(Mark mark)
        {
            Organisation organisation = null;
            switch (mark.MarkEntityType)
            {
                case MarkEntityType.Branch:
                {
                    var branch = OwnerSql.Instance.BranchRead(new Branch
                    {
                        Id = mark.EntityId
                    });
                    if (GenericEntity.HasValue(branch))
                    {
                        organisation = branch.Organisation;
                    }
                    break;
                }
                case MarkEntityType.Post:
                {
                    var post = OwnerSql.Instance.PostRead(new Post
                    {
                        Id = mark.EntityId
                    });
                    if (GenericEntity.HasValue(post))
                    {
                        organisation = post.Organisation;
                    }
                    break;
                }
            }
            return organisation;
        }

        private static BranchSplit BranchSplitCheck(BranchSplit branchSplit)
        {
            if (branchSplit != null &&
                branchSplit.IsSystem &&
                !TokenIsMaster())
            {
                ThrowException("Only system administrators can manage system branch splits and groups.");
            }
            return branchSplit;
        }

        private static BranchGroup BranchGroupCheck(BranchGroup branchGroup)
        {
            if (branchGroup != null)
            {
                BranchSplitCheck(branchGroup.BranchSplit);
            }
            return branchGroup;
        }

        private static void LoadGroups(List<Branch> branches, BondPredicate bondPredicate)
        {
            var branchIds = new Dictionary<Guid?, Branch>();
            foreach (var group in branches)
            {
                if (group == null ||
                    !group.Id.HasValue ||
                    branchIds.ContainsKey(group.Id)) continue;
                branchIds.Add(group.Id, group.Reduce<Branch>());
            }
            if (bondPredicate == null)
            {
                bondPredicate = new BondPredicate();
            }
            if (bondPredicate.GroupPredicate == null)
            {
                bondPredicate.BranchPredicate = new BranchPredicate();
            }
            bondPredicate.BranchPredicate.Branches = new Criteria<List<Branch>>(branchIds.Values.ToList());
            var bondSearch = CommonSql.Instance.BondSearch(new GenericInput<Bond, BondPredicate>
            {
                Predicate = bondPredicate
            });
            foreach (var branch in branches)
            {
                branch.Groups = bondSearch.Entities.Where(item => item.Entity.Equals(branch.Id)).Select(item => item.Group).ToList();
            }
        }

        private static void LoadBranchGroups(List<Branch> branches, BranchBondPredicate branchBondPredicate)
        {
            var branchIds = new Dictionary<Guid?, Branch>();
            foreach (var branch in branches)
            {
                if (branch == null ||
                    !branch.Id.HasValue ||
                    branchIds.ContainsKey(branch.Id)) continue;
                branchIds.Add(branch.Id, branch.Reduce<Branch>());
            }
            if (branchBondPredicate == null)
            {
                branchBondPredicate = new BranchBondPredicate();
            }
            if (branchBondPredicate.BranchPredicate == null)
            {
                branchBondPredicate.BranchPredicate = new BranchPredicate();
            }
            branchBondPredicate.BranchPredicate.Branches = new Criteria<List<Branch>>(branchIds.Values.ToList());
            var branchBondSearch = OwnerSql.Instance.BranchBondSearch(new GenericInput<BranchBond, BranchBondPredicate>
            {
                Predicate = branchBondPredicate
            });
            foreach (var branch in branches)
            {
                branch.BranchGroups = branchBondSearch.Entities.Where(item => item.Branch.Equals(branch)).Select(item => item.BranchGroup).ToList();
            }
        }

        private static void LoadBranches(List<BranchGroup> branchGroups, BranchBondPredicate branchBondPredicate)
        {
            var branchGroupIds = new Dictionary<Guid?, BranchGroup>();
            foreach (var branchGroup in branchGroups)
            {
                if (branchGroup == null ||
                    !branchGroup.Id.HasValue ||
                    branchGroupIds.ContainsKey(branchGroup.Id)) continue;
                branchGroupIds.Add(branchGroup.Id, branchGroup.Reduce<BranchGroup>());
            }
            if (branchBondPredicate == null)
            {
                branchBondPredicate = new BranchBondPredicate();
            }
            if (branchBondPredicate.BranchGroupPredicate == null)
            {
                branchBondPredicate.BranchGroupPredicate = new BranchGroupPredicate();
            }
            branchBondPredicate.BranchGroupPredicate.BranchGroups = new Criteria<List<BranchGroup>>(branchGroupIds.Values.ToList());
            var branchBondSearch = OwnerSql.Instance.BranchBondSearch(new GenericInput<BranchBond, BranchBondPredicate>
            {
                Predicate = branchBondPredicate
            });
            foreach (var branchGroup in branchGroups)
            {
                branchGroup.Branches = branchBondSearch.Entities.Where(item => item.BranchGroup.Equals(branchGroup)).Select(item => item.Branch).ToList();
            }
        }

        private static PostSplit PostSplitCheck(PostSplit postSplit)
        {
            if (postSplit != null &&
                postSplit.IsSystem &&
                !TokenIsMaster())
            {
                ThrowException("Only system administrators can manage system post splits and groups.");
            }
            return postSplit;
        }

        private static PostGroup PostGroupCheck(PostGroup postGroup)
        {
            if (postGroup != null)
            {
                PostSplitCheck(postGroup.PostSplit);
            }
            return postGroup;
        }

        private static GenericOutput<Post> PostSearch(GenericOutput<Post> genericOutput, PostPredicate postPredicate)
        {
            if (genericOutput != null &&
                genericOutput.Entities != null &&
                genericOutput.Entities.Count > 0 &&
                postPredicate != null)
            {
                if (postPredicate.LoadPostGroups)
                {
                    LoadPostGroups(genericOutput.Entities, new PostBondPredicate
                    {
                        Columns = postPredicate.HandleColumns(),
                        PostPredicate = postPredicate
                    });
                }
                if (postPredicate.LoadFilestreams)
                {
                    var filestreamPredicate = new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>())
                    };
                    foreach (var post in genericOutput.Entities)
                    {
                        filestreamPredicate.EntityIds.Value.Add(post.Id);
                        if (post.PostGroups == null) continue;
                        filestreamPredicate.EntityIds.Value.AddRange(post.PostGroups.Select(item => item.Id).ToList());
                    }
                    var filestreamSearch = CommonSql.Instance.FilestreamSearch(new GenericInput<Filestream, FilestreamPredicate>
                    {
                        Predicate = filestreamPredicate
                    });
                    foreach (var post in genericOutput.Entities)
                    {
                        post.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(post.Id)).ToList();
                        if (post.PostGroups == null) continue;
                        foreach (var postGroup in post.PostGroups)
                        {
                            postGroup.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(postGroup.Id)).ToList();
                            postGroup.Filestream = postGroup.Filestreams.Find(item => item.IsDefault);
                        }
                    }
                }
            }
            return genericOutput;
        }

        private static void LoadPostGroups(List<Post> posts, PostBondPredicate postBondPredicate)
        {
            var postIds = new Dictionary<Guid?, Post>();
            foreach (var post in posts)
            {
                if (post == null ||
                    !post.Id.HasValue ||
                    postIds.ContainsKey(post.Id)) continue;
                postIds.Add(post.Id, post.Reduce<Post>());
            }
            if (postBondPredicate == null)
            {
                postBondPredicate = new PostBondPredicate();
            }
            if (postBondPredicate.PostPredicate == null)
            {
                postBondPredicate.PostPredicate = new PostPredicate();
            }
            postBondPredicate.PostPredicate.Posts = new Criteria<List<Post>>(postIds.Values.ToList());
            var postBondSearch = OwnerSql.Instance.PostBondSearch(new GenericInput<PostBond, PostBondPredicate>
            {
                Predicate = postBondPredicate
            });
            foreach (var post in posts)
            {
                post.PostGroups = postBondSearch.Entities.Where(item => item.Post.Equals(post)).Select(item => item.PostGroup).ToList();
            }
        }

        private static void LoadPosts(List<PostGroup> postGroups, PostBondPredicate postBondPredicate)
        {
            var postGroupIds = new Dictionary<Guid?, PostGroup>();
            foreach (var postGroup in postGroups)
            {
                if (postGroup == null ||
                    !postGroup.Id.HasValue ||
                    postGroupIds.ContainsKey(postGroup.Id)) continue;
                postGroupIds.Add(postGroup.Id, postGroup.Reduce<PostGroup>());
            }
            if (postBondPredicate == null)
            {
                postBondPredicate = new PostBondPredicate();
            }
            if (postBondPredicate.PostGroupPredicate == null)
            {
                postBondPredicate.PostGroupPredicate = new PostGroupPredicate();
            }
            postBondPredicate.PostGroupPredicate.PostGroups = new Criteria<List<PostGroup>>(postGroupIds.Values.ToList());
            var postBondSearch = OwnerSql.Instance.PostBondSearch(new GenericInput<PostBond, PostBondPredicate>
            {
                Predicate = postBondPredicate
            });
            foreach (var postGroup in postGroups)
            {
                postGroup.Posts = postBondSearch.Entities.Where(item => item.PostGroup.Equals(postGroup)).Select(item => item.Post).ToList();
            }
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static OwnerLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static OwnerLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        #region Person

        public Person PersonCreate(Person person)
        {
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Account,
                    LockType.Person,
                    LockType.Filestream
                });
                person = CommonLogic.Instance.FilestreamSync(PersonSave(person, EmployeeActorType.Undefined, true), person.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return person;
        }

        public Person PersonRead(Person person)
        {
            EntityInstanceCheck(person);
            person = OwnerSql.Instance.PersonRead(person);
            if (GenericEntity.HasValue(person))
            {
                EmplacementCheck(person.Emplacement);
            }
            return person;
        }

        public Person PersonUpdate(Person person)
        {
            PersonRead(person);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Account,
                    LockType.Person,
                    LockType.Filestream
                });
                person = CommonLogic.Instance.FilestreamSync(PersonSave(person, EmployeeActorType.Undefined, false), person.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return person;
        }

        public bool PersonDelete(Person person)
        {
            var deleted = false;
            var personEntity = PersonRead(person);
            if (GenericEntity.HasValue(personEntity))
            {
                var session = Kernel.Instance.SessionManager.SessionRead();
                if (personEntity.Equals(session.Token.Person))
                {
                    ThrowException("Person [{0}] cannot remove itself.", personEntity.Code);
                }
                try
                {
                    TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                    {
                        LockType.Person,
                        LockType.Filestream
                    });
                    deleted = OwnerSql.Instance.PersonDelete(person);
                    if (GenericEntity.HasValue(personEntity))
                    {
                        CommonLogic.Instance.FilestreamRemove(new FilestreamPredicate
                        {
                            EntityIds = new Criteria<List<Guid?>>(new List<Guid?>
                            {
                                personEntity.Id
                            })
                        });
                    }
                    TransactionComplete();
                }
                catch (Exception exception)
                {
                    TransactionRollback(exception);
                }
            }
            return deleted;
        }

        public GenericOutput<Person> PersonSearch(PersonPredicate personPredicate)
        {
            return OwnerSql.Instance.PersonSearch(GenericInputCheck<Person, PersonPredicate>(personPredicate));
        }

        public static Person PersonSave(Person person, EmployeeActorType employeeActorType, bool create)
        {
            EntityPropertiesCheck(
                person,
                "Code",
                "IDNP",
                "FirstName",
                "LastName",
                "Patronymic",
                "BornOn",
                "PersonSexType");
            EntityValidate(person);
            if (person.User != null)
            {
                person.User = SecurityLogic.UserSave(person.User, employeeActorType, create);
            }
            if (create)
            {
                person.Emplacement = EmplacementCheck(person.Emplacement);
                person = OwnerSql.Instance.PersonCreate(person);
            }
            else
            {
                EmplacementCheck(person.Emplacement);
                var personEntity = OwnerSql.Instance.PersonRead(person);
                var session = Kernel.Instance.SessionManager.SessionRead();
                if (personEntity != null &&
                    personEntity.Equals(session.Token.Person) &&
                    !personEntity.LockedOn.HasValue &&
                    person.LockedOn.HasValue)
                {
                    ThrowException("Person cannot lock itself.");
                }
                person = OwnerSql.Instance.PersonUpdate(person);
                CommonLogic.Instance.TokenUpdate(person);
            }
            return person;
        }

        #endregion Person

        #region Mark

        public Mark MarkCreate(Mark mark)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!TokenIsMaster(session.Token))
            {
                mark.Person = session.Token.Person;
            }
            EntityPropertiesCheck(
                mark,
                "Person",
                "MarkEntityType",
                "EntityId",
                "MarkActionType");
            mark.SetDefaults();
            mark.UpdatedOn = null;
            mark = OwnerSql.Instance.MarkCreate(mark);
            if (mark.MarkActionType == MarkActionType.Like)
            {
                var organisation = OrganisationRead(mark);
                if (GenericEntity.HasValue(organisation))
                {
                    if (Kernel.Instance.ServerConfiguration.HangfireDisabled)
                    {
                        NotificationLogic.Instance.SubscriberSave(organisation, mark.Person);
                    }
                    else
                    {
                        BackgroundJob.Enqueue(() => NotificationLogic.Instance.SubscriberSave(organisation, mark.Person));
                    }
                }
            }
            return mark;
        }

        public Mark MarkRead(Mark mark)
        {
            EntityInstanceCheck(mark);
            mark = OwnerSql.Instance.MarkRead(mark);
            if (GenericEntity.HasValue(mark))
            {
                PersonCheck(mark.Person);
            }
            return mark;
        }

        public Mark MarkUpdate(Mark mark)
        {
            MarkRead(mark);
            EntityPropertiesCheck(
                mark,
                "MarkActionType");
            mark.UpdatedOn = DateTimeOffset.Now;
            return OwnerSql.Instance.MarkUpdate(mark);
        }

        public bool MarkDelete(Mark mark)
        {
            MarkRead(mark);
            return OwnerSql.Instance.MarkDelete(mark);
        }

        public MarkOutput MarkSearch(MarkPredicate markPredicate)
        {
            var markOutput = new MarkOutput();
            var genericInput = GenericInputCheck<Mark, MarkPredicate>(markPredicate);
            genericInput.Person = null;
            markOutput.GenericOutput = OwnerSql.Instance.MarkSearch(genericInput);
            if (markPredicate.LoadBranches)
            {
                var branches = markOutput.GenericOutput.Entities.Where(item => item.MarkEntityType == MarkEntityType.Branch).Select(item => new Branch
                {
                    Id = item.EntityId
                }).ToList();
                if (branches.Count > 0)
                {
                    markOutput.Branches = OwnerSql.Instance.BranchSearch(new GenericInput<Branch, BranchPredicate>
                    {
                        Predicate = new BranchPredicate
                        {
                            Branches = new Criteria<List<Branch>>(branches)
                        }
                    }).Entities;
                }
            }
            if (markPredicate.LoadPosts)
            {
                var posts = markOutput.GenericOutput.Entities.Where(item => item.MarkEntityType == MarkEntityType.Post).Select(item => new Post
                {
                    Id = item.EntityId
                }).ToList();
                if (posts.Count > 0)
                {
                    markOutput.Posts = OwnerSql.Instance.PostSearch(new GenericInput<Post, PostPredicate>
                    {
                        Predicate = new PostPredicate
                        {
                            Posts = new Criteria<List<Post>>(posts)
                        }
                    }).Entities;
                }
            }
            return markOutput;
        }

        public GenericOutput<MarkResume> MarkResumeSearch(MarkPredicate markPredicate)
        {
            var genericInput = GenericInputCheck<MarkResume, MarkPredicate>(markPredicate);
            genericInput.Person = null;
            genericInput.Predicate.Grouping(Kernel.Instance.TypeDeclaratorManager.Get(ClientStatic.MarkResume).PropertyDeclarators);
            return OwnerSql.Instance.MarkResumeSearch(genericInput);
        }

        #endregion Mark

        #region Organisation

        public Organisation OrganisationCreate(Organisation organisation)
        {
            EntityPropertiesCheck(
                organisation,
                "Code",
                "IDNO",
                "Name",
                "RegisteredOn",
                "OrganisationActionType");
            organisation.SetDefaults();
            organisation.Emplacement = EmplacementCheck(organisation.Emplacement);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Organisation,
                    LockType.Filestream
                });
                organisation = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.OrganisationCreate(organisation), organisation.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return organisation;
        }

        public Organisation OrganisationRead(Organisation organisation)
        {
            EntityInstanceCheck(organisation);
            organisation = OwnerSql.Instance.OrganisationRead(organisation);
            if (GenericEntity.HasValue(organisation))
            {
                OrganisationCheck(organisation);
            }
            return organisation;
        }

        public Organisation OrganisationUpdate(Organisation organisation)
        {
            EntityPropertiesCheck(
                organisation,
                "Code",
                "IDNO",
                "Name",
                "RegisteredOn",
                "OrganisationActionType");
            organisation.SetDefaults();
            OrganisationRead(organisation);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Organisation,
                    LockType.Filestream
                });
                organisation = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.OrganisationUpdate(organisation), organisation.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return organisation;
        }

        public bool OrganisationDelete(Organisation organisation)
        {
            var organisationEntity = OrganisationRead(organisation);
            var deleted = false;
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Organisation,
                    LockType.Filestream
                });
                deleted = OwnerSql.Instance.OrganisationDelete(organisation);
                if (GenericEntity.HasValue(organisationEntity))
                {
                    CommonLogic.Instance.FilestreamRemove(new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>
                        {
                            organisationEntity.Id
                        })
                    });
                }
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<Organisation> OrganisationSearch(OrganisationPredicate organisationPredicate)
        {
            var genericOutput = OwnerSql.Instance.OrganisationSearch(GenericInputCheck<Organisation, OrganisationPredicate>(organisationPredicate));
            if (genericOutput.Entities.Count > 0 &&
                organisationPredicate != null)
            {
                if (organisationPredicate.LoadFilestreams)
                {
                    var filestreamPredicate = new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>())
                    };
                    foreach (var organisation in genericOutput.Entities)
                    {
                        filestreamPredicate.EntityIds.Value.Add(organisation.Id);
                    }
                    var filestreamSearch = CommonSql.Instance.FilestreamSearch(new GenericInput<Filestream, FilestreamPredicate>
                    {
                        Predicate = filestreamPredicate
                    });
                    foreach (var organisation in genericOutput.Entities)
                    {
                        organisation.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(organisation.Id)).ToList();
                    }
                }
            }
            return genericOutput;
        }

        #endregion Organisation

        #region BranchSplit

        public BranchSplit BranchSplitCreate(BranchSplit branchSplit)
        {
            EntityPropertiesCheck(
                branchSplit,
                "Name");
            branchSplit.Organisation = OrganisationCheck(branchSplit.Organisation);
            BranchSplitCheck(branchSplit);
            return OwnerSql.Instance.BranchSplitCreate(branchSplit);
        }

        public BranchSplit BranchSplitRead(BranchSplit branchSplit)
        {
            EntityInstanceCheck(branchSplit);
            branchSplit = OwnerSql.Instance.BranchSplitRead(branchSplit);
            if (GenericEntity.HasValue(branchSplit))
            {
                OrganisationCheck(branchSplit.Organisation);
            }
            return branchSplit;
        }

        public BranchSplit BranchSplitUpdate(BranchSplit branchSplit)
        {
            EntityPropertiesCheck(
                branchSplit,
                "Code",
                "Name");
            BranchSplitCheck(BranchSplitRead(branchSplit));
            return OwnerSql.Instance.BranchSplitUpdate(branchSplit);
        }

        public bool BranchSplitDelete(BranchSplit branchSplit)
        {
            BranchSplitCheck(BranchSplitRead(branchSplit));
            return OwnerSql.Instance.BranchSplitDelete(branchSplit);
        }

        public GenericOutput<BranchSplit> BranchSplitSearch(BranchSplitPredicate branchSplitPredicate)
        {
            return OwnerSql.Instance.BranchSplitSearch(GenericInputCheck<BranchSplit, BranchSplitPredicate>(branchSplitPredicate));
        }

        #endregion BranchSplit

        #region BranchGroup

        public BranchGroup BranchGroupCreate(BranchGroup branchGroup)
        {
            EntityPropertiesCheck(
                branchGroup,
                "BranchSplit",
                "Name");
            branchGroup.BranchSplit = BranchSplitCheck(BranchSplitRead(branchGroup.BranchSplit));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Branch,
                    LockType.BranchGroup,
                    LockType.Filestream
                });
                branchGroup = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.BranchGroupCreate(branchGroup), branchGroup.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return branchGroup;
        }

        public BranchGroup BranchGroupRead(BranchGroup branchGroup)
        {
            EntityInstanceCheck(branchGroup);
            branchGroup = OwnerSql.Instance.BranchGroupRead(branchGroup);
            if (GenericEntity.HasValue(branchGroup))
            {
                OrganisationCheck(branchGroup.BranchSplit.Organisation);
            }
            return branchGroup;
        }

        public BranchGroup BranchGroupUpdate(BranchGroup branchGroup)
        {
            EntityPropertiesCheck(
                branchGroup,
                "Code",
                "Name");
            BranchGroupCheck(BranchGroupRead(branchGroup));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Branch,
                    LockType.BranchGroup,
                    LockType.Filestream
                });
                branchGroup = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.BranchGroupUpdate(branchGroup), branchGroup.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return branchGroup;
        }

        public bool BranchGroupDelete(BranchGroup branchGroup)
        {
            var deleted = false;
            var branchGroupEntity = BranchGroupCheck(BranchGroupRead(branchGroup));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Branch,
                    LockType.BranchGroup,
                    LockType.Filestream
                });
                deleted = OwnerSql.Instance.BranchGroupDelete(branchGroup);
                if (GenericEntity.HasValue(branchGroupEntity))
                {
                    CommonLogic.Instance.FilestreamRemove(new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>
                        {
                            branchGroupEntity.Id
                        })
                    });
                }
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<BranchGroup> BranchGroupSearch(BranchGroupPredicate branchGroupPredicate)
        {
            var genericOutput = OwnerSql.Instance.BranchGroupSearch(GenericInputCheck<BranchGroup, BranchGroupPredicate>(branchGroupPredicate));
            if (genericOutput.Entities.Count > 0 &&
                branchGroupPredicate != null)
            {
                if (branchGroupPredicate.LoadBranches)
                {
                    LoadBranches(genericOutput.Entities, new BranchBondPredicate
                    {
                        Columns = branchGroupPredicate.HandleColumns(),
                        BranchGroupPredicate = branchGroupPredicate
                    });
                }
                if (branchGroupPredicate.LoadFilestreams)
                {
                    var filestreamPredicate = new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>())
                    };
                    foreach (var branchGroup in genericOutput.Entities)
                    {
                        filestreamPredicate.EntityIds.Value.Add(branchGroup.Id);
                        if (branchGroup.Branches == null) continue;
                        filestreamPredicate.EntityIds.Value.AddRange(branchGroup.Branches.Select(item => item.Id).ToList());
                    }
                    var filestreamSearch = CommonSql.Instance.FilestreamSearch(new GenericInput<Filestream, FilestreamPredicate>
                    {
                        Predicate = filestreamPredicate
                    });
                    foreach (var branchGroup in genericOutput.Entities)
                    {
                        branchGroup.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(branchGroup.Id)).ToList();
                        if (branchGroup.Branches == null) continue;
                        foreach (var branch in branchGroup.Branches)
                        {
                            branch.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(branch.Id)).ToList();
                            branch.Filestream = branch.Filestreams.Find(item => item.IsDefault);
                        }
                    }
                }
            }
            return genericOutput;
        }

        #endregion BranchGroup

        #region BranchBond

        public BranchBond BranchBondRead(BranchBond branchBond)
        {
            EntityInstanceCheck(branchBond);
            branchBond = OwnerSql.Instance.BranchBondRead(branchBond);
            if (GenericEntity.HasValue(branchBond))
            {
                OrganisationCheck(branchBond.Branch.Organisation);
            }
            return branchBond;
        }

        public GenericOutput<BranchBond> BranchBondSearch(BranchBondPredicate branchBondPredicate)
        {
            return OwnerSql.Instance.BranchBondSearch(GenericInputCheck<BranchBond, BranchBondPredicate>(branchBondPredicate));
        }

        #endregion BranchBond

        #region Branch

        public Branch BranchCreate(Branch branch)
        {
            EntityPropertiesCheck(
                branch,
                "Code",
                "Name");
            branch.Organisation = OrganisationCheck(branch.Organisation);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Branch,
                    LockType.Filestream
                });
                branch = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.BranchCreate(branch), branch.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return branch;
        }

        public Branch BranchRead(Branch branch)
        {
            EntityInstanceCheck(branch);
            branch = OwnerSql.Instance.BranchRead(branch);
            if (GenericEntity.HasValue(branch))
            {
                OrganisationCheck(branch.Organisation);
            }
            return branch;
        }

        public Branch BranchUpdate(Branch branch)
        {
            EntityPropertiesCheck(
                branch,
                "Code",
                "Name");
            BranchRead(branch);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Branch,
                    LockType.Filestream
                });
                branch = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.BranchUpdate(branch), branch.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return branch;
        }

        public bool BranchDelete(Branch branch)
        {
            var branchEntity = BranchRead(branch);
            var deleted = false;
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Branch,
                    LockType.Filestream
                });
                deleted = OwnerSql.Instance.BranchDelete(branch);
                if (GenericEntity.HasValue(branchEntity))
                {
                    CommonLogic.Instance.FilestreamRemove(new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>
                        {
                            branchEntity.Id
                        })
                    });
                }
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<Branch> BranchSearch(BranchPredicate branchPredicate)
        {
            var genericOutput = OwnerSql.Instance.BranchSearch(GenericInputCheck<Branch, BranchPredicate>(branchPredicate));
            if (genericOutput.Entities.Count > 0 &&
                branchPredicate != null)
            {
                if (branchPredicate.LoadGroups)
                {
                    LoadGroups(genericOutput.Entities, new BondPredicate
                    {
                        Columns = branchPredicate.HandleColumns(),
                        BranchPredicate = branchPredicate
                    });
                }
                if (branchPredicate.LoadBranchGroups)
                {
                    LoadBranchGroups(genericOutput.Entities, new BranchBondPredicate
                    {
                        Columns = branchPredicate.HandleColumns(),
                        BranchPredicate = branchPredicate
                    });
                }
                if (branchPredicate.LoadFilestreams)
                {
                    var filestreamPredicate = new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>())
                    };
                    foreach (var branch in genericOutput.Entities)
                    {
                        filestreamPredicate.EntityIds.Value.Add(branch.Id);
                        if (branch.BranchGroups == null) continue;
                        filestreamPredicate.EntityIds.Value.AddRange(branch.BranchGroups.Select(item => item.Id).ToList());
                    }
                    var filestreamSearch = CommonSql.Instance.FilestreamSearch(new GenericInput<Filestream, FilestreamPredicate>
                    {
                        Predicate = filestreamPredicate
                    });
                    foreach (var branch in genericOutput.Entities)
                    {
                        branch.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(branch.Id)).ToList();
                        if (branch.BranchGroups == null) continue;
                        foreach (var branchGroup in branch.BranchGroups)
                        {
                            branchGroup.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(branchGroup.Id)).ToList();
                            branchGroup.Filestream = branchGroup.Filestreams.Find(item => item.IsDefault);
                        }
                    }
                }
            }
            return genericOutput;
        }

        #endregion Branch

        #region Range

        public Range RangeCreate(Range range)
        {
            EntityPropertiesCheck(
                range,
                "Branch",
                "Code",
                "IPDataFrom",
                "IPDataTo");
            EntityValidate(range);
            range.Branch = BranchCheck(range.Branch);
            return OwnerSql.Instance.RangeCreate(range);
        }

        public Range RangeRead(Range range)
        {
            EntityInstanceCheck(range);
            range = OwnerSql.Instance.RangeRead(range);
            if (GenericEntity.HasValue(range))
            {
                BranchCheck(range.Branch);
            }
            return range;
        }

        public Range RangeUpdate(Range range)
        {
            EntityPropertiesCheck(
                range,
                "Branch",
                "Code",
                "IPDataFrom",
                "IPDataTo");
            EntityValidate(range);
            RangeRead(range);
            return OwnerSql.Instance.RangeUpdate(range);
        }

        public bool RangeDelete(Range range)
        {
            RangeRead(range);
            return OwnerSql.Instance.RangeDelete(range);
        }

        public GenericOutput<Range> RangeSearch(RangePredicate rangePredicate)
        {
            return OwnerSql.Instance.RangeSearch(GenericInputCheck<Range, RangePredicate>(rangePredicate));
        }

        #endregion Range

        #region Employee

        public Employee EmployeeCreate(Employee employee)
        {
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Account,
                    LockType.Person,
                    LockType.Employee,
                    LockType.Filestream
                });
                var employeeEntity = CommonLogic.Instance.FilestreamSync(EmployeeSave(employee, true), employee.Filestreams);
                employeeEntity.State = employee.State;
                employee = OwnerSql.Instance.EmployeeRead(employeeEntity);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return employee;
        }

        public Employee EmployeeRead(Employee employee)
        {
            EntityInstanceCheck(employee);
            employee = OwnerSql.Instance.EmployeeRead(employee);
            if (GenericEntity.HasValue(employee))
            {
                OrganisationCheck(employee.Organisation);
            }
            return employee;
        }

        public Employee EmployeeUpdate(Employee employee)
        {
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Account,
                    LockType.Person,
                    LockType.Employee,
                    LockType.Filestream
                });
                var employeeEntity = CommonLogic.Instance.FilestreamSync(EmployeeSave(employee, false), employee.Filestreams);
                employeeEntity.State = employee.State;
                employee = OwnerSql.Instance.EmployeeRead(employeeEntity);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return employee;
        }

        public bool EmployeeDelete(Employee employee)
        {
            var deleted = false;
            var employeeEntity = EmployeeRead(employee);
            if (GenericEntity.HasValue(employeeEntity))
            {
                var session = Kernel.Instance.SessionManager.SessionRead();
                if (session.Token.Employees != null)
                {
                    foreach (var item in session.Token.Employees)
                    {
                        if (!item.Equals(employeeEntity)) continue;
                        ThrowException("Employee [{0}] cannot remove itself.", item.Person.Code);
                    }
                }
                try
                {
                    TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                    {
                        LockType.Employee,
                        LockType.Filestream
                    });
                    deleted = OwnerSql.Instance.EmployeeDelete(employee);
                    CommonLogic.Instance.FilestreamRemove(new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>
                        {
                            employeeEntity.Id
                        })
                    });
                    TransactionComplete();
                }
                catch (Exception exception)
                {
                    TransactionRollback(exception);
                }
            }
            return deleted;
        }

        public GenericOutput<Employee> EmployeeSearch(EmployeePredicate employeePredicate)
        {
            return OwnerSql.Instance.EmployeeSearch(GenericInputCheck<Employee, EmployeePredicate>(employeePredicate));
        }

        public static Employee EmployeeSave(Employee employee, bool create, bool checkOrganisation = true)
        {
            EntityPropertiesCheck(
                employee,
                "Function",
                "EmployeeActorType",
                "State.IsActive");
            employee.Person = PersonSave(employee.Person, employee.EmployeeActorType, create);
            employee.State = Kernel.Instance.StateGenerate(employee.State);
            if (create)
            {
                employee.SetDefaults();
                if (checkOrganisation)
                {
                    employee.Organisation = OrganisationCheck(employee.Organisation);
                }
                employee = OwnerSql.Instance.EmployeeCreate(employee);
            }
            else
            {
                if (checkOrganisation)
                {
                    OrganisationCheck(employee.Organisation);
                }
                employee = OwnerSql.Instance.EmployeeUpdate(employee);
                CommonLogic.Instance.TokenUpdate(employee);
            }
            NotificationLogic.Instance.SubscriberSave(employee.Organisation, employee.Person);
            return employee;
        }

        #endregion Employee

        #region PostSplit

        public PostSplit PostSplitCreate(PostSplit postSplit)
        {
            EntityPropertiesCheck(
                postSplit,
                "Name");
            postSplit.Organisation = OrganisationCheck(postSplit.Organisation);
            PostSplitCheck(postSplit);
            return OwnerSql.Instance.PostSplitCreate(postSplit);
        }

        public PostSplit PostSplitRead(PostSplit postSplit)
        {
            EntityInstanceCheck(postSplit);
            postSplit = OwnerSql.Instance.PostSplitRead(postSplit);
            if (GenericEntity.HasValue(postSplit))
            {
                OrganisationCheck(postSplit.Organisation);
            }
            return postSplit;
        }

        public PostSplit PostSplitUpdate(PostSplit postSplit)
        {
            EntityPropertiesCheck(
                postSplit,
                "Code",
                "Name");
            PostSplitCheck(PostSplitRead(postSplit));
            return OwnerSql.Instance.PostSplitUpdate(postSplit);
        }

        public bool PostSplitDelete(PostSplit postSplit)
        {
            PostSplitCheck(PostSplitRead(postSplit));
            return OwnerSql.Instance.PostSplitDelete(postSplit);
        }

        public GenericOutput<PostSplit> PostSplitSearch(PostSplitPredicate postSplitPredicate)
        {
            return OwnerSql.Instance.PostSplitSearch(GenericInputCheck<PostSplit, PostSplitPredicate>(postSplitPredicate));
        }

        #endregion PostSplit

        #region PostGroup

        public PostGroup PostGroupCreate(PostGroup postGroup)
        {
            EntityPropertiesCheck(
                postGroup,
                "PostSplit",
                "Name");
            postGroup.PostSplit = PostSplitCheck(PostSplitRead(postGroup.PostSplit));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Post,
                    LockType.PostGroup,
                    LockType.Filestream
                });
                postGroup = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.PostGroupCreate(postGroup), postGroup.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return postGroup;
        }

        public PostGroup PostGroupRead(PostGroup postGroup)
        {
            EntityInstanceCheck(postGroup);
            postGroup = OwnerSql.Instance.PostGroupRead(postGroup);
            if (GenericEntity.HasValue(postGroup))
            {
                OrganisationCheck(postGroup.PostSplit.Organisation);
            }
            return postGroup;
        }

        public PostGroup PostGroupUpdate(PostGroup postGroup)
        {
            EntityPropertiesCheck(
                postGroup,
                "Code",
                "Name");
            PostGroupCheck(PostGroupRead(postGroup));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Post,
                    LockType.PostGroup,
                    LockType.Filestream
                });
                postGroup = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.PostGroupUpdate(postGroup), postGroup.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return postGroup;
        }

        public bool PostGroupDelete(PostGroup postGroup)
        {
            var deleted = false;
            var postGroupEntity = PostGroupCheck(PostGroupRead(postGroup));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Post,
                    LockType.PostGroup,
                    LockType.Filestream
                });
                deleted = OwnerSql.Instance.PostGroupDelete(postGroup);
                if (GenericEntity.HasValue(postGroupEntity))
                {
                    CommonLogic.Instance.FilestreamRemove(new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>
                        {
                            postGroupEntity.Id
                        })
                    });
                }
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<PostGroup> PostGroupSearch(PostGroupPredicate postGroupPredicate)
        {
            var genericOutput = OwnerSql.Instance.PostGroupSearch(GenericInputCheck<PostGroup, PostGroupPredicate>(postGroupPredicate));
            if (genericOutput.Entities.Count > 0 &&
                postGroupPredicate != null)
            {
                if (postGroupPredicate.LoadPosts)
                {
                    LoadPosts(genericOutput.Entities, new PostBondPredicate
                    {
                        Columns = postGroupPredicate.HandleColumns(),
                        PostGroupPredicate = postGroupPredicate
                    });
                }
                if (postGroupPredicate.LoadFilestreams)
                {
                    var filestreamPredicate = new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>())
                    };
                    foreach (var postGroup in genericOutput.Entities)
                    {
                        filestreamPredicate.EntityIds.Value.Add(postGroup.Id);
                        if (postGroup.Posts == null) continue;
                        filestreamPredicate.EntityIds.Value.AddRange(postGroup.Posts.Select(item => item.Id).ToList());
                    }
                    var filestreamSearch = CommonSql.Instance.FilestreamSearch(new GenericInput<Filestream, FilestreamPredicate>
                    {
                        Predicate = filestreamPredicate
                    });
                    foreach (var postGroup in genericOutput.Entities)
                    {
                        postGroup.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(postGroup.Id)).ToList();
                        if (postGroup.Posts == null) continue;
                        foreach (var post in postGroup.Posts)
                        {
                            post.Filestreams = filestreamSearch.Entities.Where(item => item.EntityId.Equals(post.Id)).ToList();
                            post.Filestream = post.Filestreams.Find(item => item.IsDefault);
                        }
                    }
                }
            }
            return genericOutput;
        }

        #endregion PostGroup

        #region PostBond

        public PostBond PostBondRead(PostBond postBond)
        {
            EntityInstanceCheck(postBond);
            postBond = OwnerSql.Instance.PostBondRead(postBond);
            if (GenericEntity.HasValue(postBond))
            {
                OrganisationCheck(postBond.Post.Organisation);
            }
            return postBond;
        }

        public GenericOutput<PostBond> PostBondSearch(PostBondPredicate postBondPredicate)
        {
            return OwnerSql.Instance.PostBondSearch(GenericInputCheck<PostBond, PostBondPredicate>(postBondPredicate));
        }

        #endregion PostBond

        #region Post

        public Post PostCreate(Post post)
        {
            EntityPropertiesCheck(
                post,
                "Date",
                "Title",
                "PostActionType");
            post.Organisation = OrganisationCheck(post.Organisation);
            post.SetDefaults();
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Post,
                    LockType.Filestream
                });
                post = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.PostCreate(post), post.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return post;
        }

        public Post PostRead(Post post)
        {
            EntityInstanceCheck(post);
            post = OwnerSql.Instance.PostRead(post);
            if (GenericEntity.HasValue(post))
            {
                OrganisationCheck(post.Organisation);
            }
            return post;
        }

        public Post PostUpdate(Post post)
        {
            EntityPropertiesCheck(
                post,
                "Code",
                "Date",
                "Title",
                "PostActionType");
            PostRead(post);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Post,
                    LockType.Filestream
                });
                post = CommonLogic.Instance.FilestreamSync(OwnerSql.Instance.PostUpdate(post), post.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return post;
        }

        public bool PostDelete(Post post)
        {
            var postEntity = PostRead(post);
            var deleted = false;
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Post,
                    LockType.Filestream
                });
                deleted = OwnerSql.Instance.PostDelete(post);
                if (GenericEntity.HasValue(postEntity))
                {
                    CommonLogic.Instance.FilestreamRemove(new FilestreamPredicate
                    {
                        EntityIds = new Criteria<List<Guid?>>(new List<Guid?>
                        {
                            postEntity.Id
                        })
                    });
                }
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<Post> PostSearch(PostPredicate postPredicate)
        {
            return PostSearch(OwnerSql.Instance.PostSearch(GenericInputCheck<Post, PostPredicate>(postPredicate)), postPredicate);
        }

        public GenericOutput<Post> PostSearchPublic(PostPredicate postPredicate)
        {
            var genericInput = GenericInputCheck<Post, PostPredicate>(postPredicate);
            genericInput.Organisations = null;
            if (genericInput.Predicate.PostActionType == null)
            {
                genericInput.Predicate.PostActionType = new Criteria<Flags<PostActionType>>();
            }
            if (genericInput.Predicate.PostActionType.Value == null)
            {
                genericInput.Predicate.PostActionType.Value = new Flags<PostActionType>();
            }
            genericInput.Predicate.PostActionType.Value.AddValue(PostActionType.Public);
            genericInput.Predicate.PostActionType.IsExcluded = false;
            var genericOutput = OwnerSql.Instance.PostSearch(genericInput);
            return PostSearch(genericOutput, postPredicate);
        }

        #endregion Post

        #region Layout

        public Layout LayoutCreate(Layout layout)
        {
            EntityPropertiesCheck(
                layout,
                "LayoutEntityType",
                "Name");
            layout.Organisation = OrganisationCheck(layout.Organisation);
            return OwnerSql.Instance.LayoutCreate(layout);
        }

        public Layout LayoutRead(Layout layout)
        {
            EntityInstanceCheck(layout);
            layout = OwnerSql.Instance.LayoutRead(layout);
            if (GenericEntity.HasValue(layout))
            {
                OrganisationCheck(layout.Organisation);
            }
            return layout;
        }

        public Layout LayoutUpdate(Layout layout)
        {
            EntityPropertiesCheck(
                layout,
                "Code",
                "Name");
            LayoutRead(layout);
            return OwnerSql.Instance.LayoutUpdate(layout);
        }

        public bool LayoutDelete(Layout layout)
        {
            LayoutRead(layout);
            return OwnerSql.Instance.LayoutDelete(layout);
        }

        public GenericOutput<Layout> LayoutSearch(LayoutPredicate layoutPredicate)
        {
            return OwnerSql.Instance.LayoutSearch(GenericInputCheck<Layout, LayoutPredicate>(layoutPredicate));
        }

        #endregion Layout

        #endregion Methods

        #endregion Public Members
    }
}