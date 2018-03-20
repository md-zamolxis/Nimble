#region Using

using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Engine.Core;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataTransport;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class OwnerSql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly OwnerSql instance = new OwnerSql(Kernel.Instance.ServerConfiguration.GenericDatabase);

        #endregion Properties

        #region Methods

        private OwnerSql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static OwnerSql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public OwnerSql() { }

        #region Person

        public Person PersonCreate(Person person)
        {
            return EntityAction(PermissionType.PersonCreate, person).Entity;
        }

        public Person PersonRead(Person person)
        {
            return EntityAction(PermissionType.PersonRead, person).Entity;
        }

        public Person PersonUpdate(Person person)
        {
            return EntityAction(PermissionType.PersonUpdate, person).Entity;
        }

        public bool PersonDelete(Person person)
        {
            return EntityDelete(PermissionType.PersonDelete, person);
        }

        public GenericOutput<Person> PersonSearch(GenericInput<Person, PersonPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PersonSearch;
            return EntityAction(genericInput);
        }

        #endregion Person

        #region Mark

        public Mark MarkCreate(Mark mark)
        {
            return EntityAction(PermissionType.MarkCreate, mark).Entity;
        }

        public Mark MarkRead(Mark mark)
        {
            return EntityAction(PermissionType.MarkRead, mark).Entity;
        }

        public Mark MarkUpdate(Mark mark)
        {
            return EntityAction(PermissionType.MarkUpdate, mark).Entity;
        }

        public bool MarkDelete(Mark mark)
        {
            return EntityDelete(PermissionType.MarkDelete, mark);
        }

        public GenericOutput<Mark> MarkSearch(GenericInput<Mark, MarkPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.MarkSearch;
            return EntityAction(genericInput);
        }

        public GenericOutput<MarkResume> MarkResumeSearch(GenericInput<MarkResume, MarkPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.MarkResumeSearch;
            return EntityAction(ClientStatic.Mark, genericInput);
        }

        #endregion Mark

        #region Organisation

        public Organisation OrganisationCreate(Organisation organisation)
        {
            return EntityAction(PermissionType.OrganisationCreate, organisation).Entity;
        }

        public Organisation OrganisationRead(Organisation organisation)
        {
            return EntityAction(PermissionType.OrganisationRead, organisation).Entity;
        }

        public Organisation OrganisationUpdate(Organisation organisation)
        {
            return EntityAction(PermissionType.OrganisationUpdate, organisation).Entity;
        }

        public bool OrganisationDelete(Organisation organisation)
        {
            return EntityDelete(PermissionType.OrganisationDelete, organisation);
        }

        public GenericOutput<Organisation> OrganisationSearch(GenericInput<Organisation, OrganisationPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.OrganisationSearch;
            return EntityAction(genericInput);
        }

        #endregion Organisation

        #region BranchSplit

        public BranchSplit BranchSplitCreate(BranchSplit branchSplit)
        {
            return EntityAction(PermissionType.BranchSplitCreate, branchSplit).Entity;
        }

        public BranchSplit BranchSplitRead(BranchSplit branchSplit)
        {
            return EntityAction(PermissionType.BranchSplitRead, branchSplit).Entity;
        }

        public BranchSplit BranchSplitUpdate(BranchSplit branchSplit)
        {
            return EntityAction(PermissionType.BranchSplitUpdate, branchSplit).Entity;
        }

        public bool BranchSplitDelete(BranchSplit branchSplit)
        {
            return EntityDelete(PermissionType.BranchSplitDelete, branchSplit);
        }

        public GenericOutput<BranchSplit> BranchSplitSearch(GenericInput<BranchSplit, BranchSplitPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BranchSplitSearch;
            return EntityAction(genericInput);
        }

        #endregion BranchSplit

        #region BranchGroup

        public BranchGroup BranchGroupCreate(BranchGroup branchGroup)
        {
            return EntityAction(PermissionType.BranchGroupCreate, branchGroup).Entity;
        }

        public BranchGroup BranchGroupRead(BranchGroup branchGroup)
        {
            return EntityAction(PermissionType.BranchGroupRead, branchGroup).Entity;
        }

        public BranchGroup BranchGroupUpdate(BranchGroup branchGroup)
        {
            return EntityAction(PermissionType.BranchGroupUpdate, branchGroup).Entity;
        }

        public bool BranchGroupDelete(BranchGroup branchGroup)
        {
            return EntityDelete(PermissionType.BranchGroupDelete, branchGroup);
        }

        public GenericOutput<BranchGroup> BranchGroupSearch(GenericInput<BranchGroup, BranchGroupPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BranchGroupSearch;
            return EntityAction(genericInput);
        }

        #endregion BranchGroup

        #region BranchBond

        public BranchBond BranchBondRead(BranchBond branchBond)
        {
            return EntityAction(PermissionType.BranchBondRead, branchBond).Entity;
        }

        public GenericOutput<BranchBond> BranchBondSearch(GenericInput<BranchBond, BranchBondPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BranchBondSearch;
            return EntityAction(genericInput);
        }

        #endregion BranchBond

        #region Branch

        public Branch BranchCreate(Branch branch)
        {
            return EntityAction(PermissionType.BranchCreate, branch).Entity;
        }

        public Branch BranchRead(Branch branch)
        {
            return EntityAction(PermissionType.BranchRead, branch).Entity;
        }

        public Branch BranchUpdate(Branch branch)
        {
            return EntityAction(PermissionType.BranchUpdate, branch).Entity;
        }

        public bool BranchDelete(Branch branch)
        {
            return EntityDelete(PermissionType.BranchDelete, branch);
        }

        public GenericOutput<Branch> BranchSearch(GenericInput<Branch, BranchPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BranchSearch;
            return EntityAction(genericInput);
        }

        #endregion Branch

        #region Range

        public Range RangeCreate(Range range)
        {
            return EntityAction(PermissionType.RangeCreate, range).Entity;
        }

        public Range RangeRead(Range range)
        {
            return EntityAction(PermissionType.RangeRead, range).Entity;
        }

        public Range RangeUpdate(Range range)
        {
            return EntityAction(PermissionType.RangeUpdate, range).Entity;
        }

        public bool RangeDelete(Range range)
        {
            return EntityDelete(PermissionType.RangeDelete, range);
        }

        public GenericOutput<Range> RangeSearch(GenericInput<Range, RangePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.RangeSearch;
            return EntityAction(genericInput);
        }

        #endregion Range

        #region Employee

        public Employee EmployeeCreate(Employee employee)
        {
            return EntityAction(PermissionType.EmployeeCreate, employee).Entity;
        }

        public Employee EmployeeRead(Employee employee)
        {
            return EntityAction(PermissionType.EmployeeRead, employee).Entity;
        }

        public Employee EmployeeUpdate(Employee employee)
        {
            return EntityAction(PermissionType.EmployeeUpdate, employee).Entity;
        }

        public bool EmployeeDelete(Employee employee)
        {
            return EntityDelete(PermissionType.EmployeeDelete, employee);
        }

        public GenericOutput<Employee> EmployeeSearch(GenericInput<Employee, EmployeePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.EmployeeSearch;
            return EntityAction(genericInput);
        }

        #endregion Organisation

        #region PostSplit

        public PostSplit PostSplitCreate(PostSplit postSplit)
        {
            return EntityAction(PermissionType.PostSplitCreate, postSplit).Entity;
        }

        public PostSplit PostSplitRead(PostSplit postSplit)
        {
            return EntityAction(PermissionType.PostSplitRead, postSplit).Entity;
        }

        public PostSplit PostSplitUpdate(PostSplit postSplit)
        {
            return EntityAction(PermissionType.PostSplitUpdate, postSplit).Entity;
        }

        public bool PostSplitDelete(PostSplit postSplit)
        {
            return EntityDelete(PermissionType.PostSplitDelete, postSplit);
        }

        public GenericOutput<PostSplit> PostSplitSearch(GenericInput<PostSplit, PostSplitPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PostSplitSearch;
            return EntityAction(genericInput);
        }

        #endregion PostSplit

        #region PostGroup

        public PostGroup PostGroupCreate(PostGroup postGroup)
        {
            return EntityAction(PermissionType.PostGroupCreate, postGroup).Entity;
        }

        public PostGroup PostGroupRead(PostGroup postGroup)
        {
            return EntityAction(PermissionType.PostGroupRead, postGroup).Entity;
        }

        public PostGroup PostGroupUpdate(PostGroup postGroup)
        {
            return EntityAction(PermissionType.PostGroupUpdate, postGroup).Entity;
        }

        public bool PostGroupDelete(PostGroup postGroup)
        {
            return EntityDelete(PermissionType.PostGroupDelete, postGroup);
        }

        public GenericOutput<PostGroup> PostGroupSearch(GenericInput<PostGroup, PostGroupPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PostGroupSearch;
            return EntityAction(genericInput);
        }

        #endregion PostGroup

        #region PostBond

        public PostBond PostBondRead(PostBond postBond)
        {
            return EntityAction(PermissionType.PostBondRead, postBond).Entity;
        }

        public GenericOutput<PostBond> PostBondSearch(GenericInput<PostBond, PostBondPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PostBondSearch;
            return EntityAction(genericInput);
        }

        #endregion PostBond

        #region Post

        public Post PostCreate(Post post)
        {
            return EntityAction(PermissionType.PostCreate, post).Entity;
        }

        public Post PostRead(Post post)
        {
            return EntityAction(PermissionType.PostRead, post).Entity;
        }

        public Post PostUpdate(Post post)
        {
            return EntityAction(PermissionType.PostUpdate, post).Entity;
        }

        public bool PostDelete(Post post)
        {
            return EntityDelete(PermissionType.PostDelete, post);
        }

        public GenericOutput<Post> PostSearch(GenericInput<Post, PostPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PostSearch;
            return EntityAction(genericInput);
        }

        #endregion Post

        #region Layout

        public Layout LayoutCreate(Layout layout)
        {
            return EntityAction(PermissionType.LayoutCreate, layout).Entity;
        }

        public Layout LayoutRead(Layout layout)
        {
            return EntityAction(PermissionType.LayoutRead, layout).Entity;
        }

        public Layout LayoutUpdate(Layout layout)
        {
            return EntityAction(PermissionType.LayoutUpdate, layout).Entity;
        }

        public bool LayoutDelete(Layout layout)
        {
            return EntityDelete(PermissionType.LayoutDelete, layout);
        }

        public GenericOutput<Layout> LayoutSearch(GenericInput<Layout, LayoutPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.LayoutSearch;
            return EntityAction(genericInput);
        }

        #endregion Layout

        #endregion Methods

        #endregion Public Members
    }
}
