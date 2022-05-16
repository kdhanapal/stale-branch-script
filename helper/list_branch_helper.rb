# frozen_string_literal: true

require_relative '../constant/stale_branch_constant'

# Helper Module for List Of Branches
module ListBranchHelper
  include StaleBranchConstant

  def branches_report_per_page(page_num = 1)
    branch_report = []
    list_branch_url = StaleBranchConstant::LIST_BRANCH_BASE_URL + page_num.to_s + "&per_page=#{StaleBranchConstant::BRANCH_PER_PAGE}"
    current_branches = HTTParty.get(list_branch_url, headers: StaleBranchConstant::HEADERS)
    current_branches.each do |branch|
      com_det = HTTParty.get(branch['commit']['url'], headers: StaleBranchConstant::HEADERS)
      committer = com_det['commit']['committer']
      branch_report << {
        name: branch['name'],
        c_date: committer['date']
      }
    end
    { 'b_r': branch_report }  
  end

  # returns true if the branch is not whitelised.
  def branch_not_whitelisted?(branch)
    !branch.end_with? WHITELISTED_BRANCH_SUFFIX
  end
end
