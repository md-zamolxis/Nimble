#region Using

using System.ServiceModel.Activation;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.DataTransport;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Owner : IOwner
    {
        #region Person

        public Person PersonCreate(Person person)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PersonCreate).PersonCreate(person);
        }

        public Person PersonRead(Person person)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PersonRead).PersonRead(person);
        }

        public Person PersonUpdate(Person person)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PersonUpdate).PersonUpdate(person);
        }

        public bool PersonDelete(Person person)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PersonDelete).PersonDelete(person);
        }

        public GenericOutput<Person> PersonSearch(PersonPredicate personPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PersonSearch).PersonSearch(personPredicate);
        }

        #endregion Person

        #region Mark

        public Mark MarkCreate(Mark mark)
        {
            return OwnerLogic.InstanceCheck(PermissionType.MarkCreate).MarkCreate(mark);
        }

        public Mark MarkRead(Mark mark)
        {
            return OwnerLogic.InstanceCheck(PermissionType.MarkRead).MarkRead(mark);
        }

        public Mark MarkUpdate(Mark mark)
        {
            return OwnerLogic.InstanceCheck(PermissionType.MarkUpdate).MarkUpdate(mark);
        }

        public bool MarkDelete(Mark mark)
        {
            return OwnerLogic.InstanceCheck(PermissionType.MarkDelete).MarkDelete(mark);
        }

        public MarkOutput MarkSearch(MarkPredicate markPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.MarkSearch).MarkSearch(markPredicate);
        }

        public GenericOutput<MarkResume> MarkResumeSearch(MarkPredicate markPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.MarkSearch).MarkResumeSearch(markPredicate);
        }

        #endregion Mark

        #region Organisation

        public Organisation OrganisationCreate(Organisation organisation)
        {
            return OwnerLogic.InstanceCheck(PermissionType.OrganisationCreate).OrganisationCreate(organisation);
        }

        public Organisation OrganisationRead(Organisation organisation)
        {
            return OwnerLogic.InstanceCheck(PermissionType.OrganisationRead).OrganisationRead(organisation);
        }

        public Organisation OrganisationUpdate(Organisation organisation)
        {
            return OwnerLogic.InstanceCheck(PermissionType.OrganisationUpdate).OrganisationUpdate(organisation);
        }

        public bool OrganisationDelete(Organisation organisation)
        {
            return OwnerLogic.InstanceCheck(PermissionType.OrganisationDelete).OrganisationDelete(organisation);
        }

        public GenericOutput<Organisation> OrganisationSearch(OrganisationPredicate organisationPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.OrganisationSearch).OrganisationSearch(organisationPredicate);
        }

        #endregion Organisation

        #region BranchSplit

        public BranchSplit BranchSplitCreate(BranchSplit branchSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchSplitCreate).BranchSplitCreate(branchSplit);
        }

        public BranchSplit BranchSplitRead(BranchSplit branchSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchSplitRead).BranchSplitRead(branchSplit);
        }

        public BranchSplit BranchSplitUpdate(BranchSplit branchSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchSplitUpdate).BranchSplitUpdate(branchSplit);
        }

        public bool BranchSplitDelete(BranchSplit branchSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchSplitDelete).BranchSplitDelete(branchSplit);
        }

        public GenericOutput<BranchSplit> BranchSplitSearch(BranchSplitPredicate branchSplitPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchSplitSearch).BranchSplitSearch(branchSplitPredicate);
        }

        #endregion BranchSplit

        #region BranchGroup

        public BranchGroup BranchGroupCreate(BranchGroup branchGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchGroupCreate).BranchGroupCreate(branchGroup);
        }

        public BranchGroup BranchGroupRead(BranchGroup branchGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchGroupRead).BranchGroupRead(branchGroup);
        }

        public BranchGroup BranchGroupUpdate(BranchGroup branchGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchGroupUpdate).BranchGroupUpdate(branchGroup);
        }

        public bool BranchGroupDelete(BranchGroup branchGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchGroupDelete).BranchGroupDelete(branchGroup);
        }

        public GenericOutput<BranchGroup> BranchGroupSearch(BranchGroupPredicate branchGroupPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchGroupSearch).BranchGroupSearch(branchGroupPredicate);
        }

        #endregion BranchGroup

        #region BranchBond

        public BranchBond BranchBondRead(BranchBond branchBond)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchBondRead).BranchBondRead(branchBond);
        }

        public GenericOutput<BranchBond> BranchBondSearch(BranchBondPredicate branchBondPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchBondSearch).BranchBondSearch(branchBondPredicate);

        }

        #endregion BranchBond

        #region Branch

        public Branch BranchCreate(Branch branch)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchCreate).BranchCreate(branch);
        }

        public Branch BranchRead(Branch branch)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchRead).BranchRead(branch);
        }

        public Branch BranchUpdate(Branch branch)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchUpdate).BranchUpdate(branch);
        }

        public bool BranchDelete(Branch branch)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchDelete).BranchDelete(branch);
        }

        public GenericOutput<Branch> BranchSearch(BranchPredicate branchPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.BranchSearch).BranchSearch(branchPredicate);
        }

        #endregion Branch

        #region Range

        public Range RangeCreate(Range range)
        {
            return OwnerLogic.InstanceCheck(PermissionType.RangeCreate).RangeCreate(range);
        }

        public Range RangeRead(Range range)
        {
            return OwnerLogic.InstanceCheck(PermissionType.RangeRead).RangeRead(range);
        }

        public Range RangeUpdate(Range range)
        {
            return OwnerLogic.InstanceCheck(PermissionType.RangeUpdate).RangeUpdate(range);
        }

        public bool RangeDelete(Range range)
        {
            return OwnerLogic.InstanceCheck(PermissionType.RangeDelete).RangeDelete(range);
        }

        public GenericOutput<Range> RangeSearch(RangePredicate rangePredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.RangeSearch).RangeSearch(rangePredicate);
        }

        #endregion Range

        #region Employee

        public Employee EmployeeCreate(Employee employee)
        {
            return OwnerLogic.InstanceCheck(PermissionType.EmployeeCreate).EmployeeCreate(employee);
        }

        public Employee EmployeeRead(Employee employee)
        {
            return OwnerLogic.InstanceCheck(PermissionType.EmployeeRead).EmployeeRead(employee);
        }

        public Employee EmployeeUpdate(Employee employee)
        {
            return OwnerLogic.InstanceCheck(PermissionType.EmployeeUpdate).EmployeeUpdate(employee);
        }

        public bool EmployeeDelete(Employee employee)
        {
            return OwnerLogic.InstanceCheck(PermissionType.EmployeeDelete).EmployeeDelete(employee);
        }

        public GenericOutput<Employee> EmployeeSearch(EmployeePredicate employeePredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.EmployeeSearch).EmployeeSearch(employeePredicate);
        }

        #endregion Employee

        #region PostSplit

        public PostSplit PostSplitCreate(PostSplit postSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostSplitCreate).PostSplitCreate(postSplit);
        }

        public PostSplit PostSplitRead(PostSplit postSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostSplitRead).PostSplitRead(postSplit);
        }

        public PostSplit PostSplitUpdate(PostSplit postSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostSplitUpdate).PostSplitUpdate(postSplit);
        }

        public bool PostSplitDelete(PostSplit postSplit)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostSplitDelete).PostSplitDelete(postSplit);
        }

        public GenericOutput<PostSplit> PostSplitSearch(PostSplitPredicate postSplitPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostSplitSearch).PostSplitSearch(postSplitPredicate);
        }

        #endregion PostSplit

        #region PostGroup

        public PostGroup PostGroupCreate(PostGroup postGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostGroupCreate).PostGroupCreate(postGroup);
        }

        public PostGroup PostGroupRead(PostGroup postGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostGroupRead).PostGroupRead(postGroup);
        }

        public PostGroup PostGroupUpdate(PostGroup postGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostGroupUpdate).PostGroupUpdate(postGroup);
        }

        public bool PostGroupDelete(PostGroup postGroup)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostGroupDelete).PostGroupDelete(postGroup);
        }

        public GenericOutput<PostGroup> PostGroupSearch(PostGroupPredicate postGroupPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostGroupSearch).PostGroupSearch(postGroupPredicate);
        }

        #endregion PostGroup

        #region PostBond

        public PostBond PostBondRead(PostBond postBond)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostBondRead).PostBondRead(postBond);
        }

        public GenericOutput<PostBond> PostBondSearch(PostBondPredicate postBondPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostBondSearch).PostBondSearch(postBondPredicate);

        }

        #endregion PostBond

        #region Post

        public Post PostCreate(Post post)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostCreate).PostCreate(post);
        }

        public Post PostRead(Post post)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostRead).PostRead(post);
        }

        public Post PostUpdate(Post post)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostUpdate).PostUpdate(post);
        }

        public bool PostDelete(Post post)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostDelete).PostDelete(post);
        }

        public GenericOutput<Post> PostSearch(PostPredicate postPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.PostSearch).PostSearch(postPredicate);
        }

        public GenericOutput<Post> PostSearchPublic(PostPredicate postPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.Public).PostSearchPublic(postPredicate);
        }

        #endregion Post

        #region Layout

        public Layout LayoutCreate(Layout layout)
        {
            return OwnerLogic.InstanceCheck(PermissionType.LayoutCreate).LayoutCreate(layout);
        }

        public Layout LayoutRead(Layout layout)
        {
            return OwnerLogic.InstanceCheck(PermissionType.LayoutRead).LayoutRead(layout);
        }

        public Layout LayoutUpdate(Layout layout)
        {
            return OwnerLogic.InstanceCheck(PermissionType.LayoutUpdate).LayoutUpdate(layout);
        }

        public bool LayoutDelete(Layout layout)
        {
            return OwnerLogic.InstanceCheck(PermissionType.LayoutDelete).LayoutDelete(layout);
        }

        public GenericOutput<Layout> LayoutSearch(LayoutPredicate layoutPredicate)
        {
            return OwnerLogic.InstanceCheck(PermissionType.LayoutSearch).LayoutSearch(layoutPredicate);
        }

        #endregion Layout
    }
}