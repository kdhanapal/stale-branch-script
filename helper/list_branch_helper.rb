# frozen_string_literal: true

require_relative '../constant/stale_branch_constant'

# Helper Module for List Of Branches
module ListBranchHelper
  include StaleBranchConstant
  def list_branches(page_num = 1, per_page)
    list_branch_url = StaleBranchConstant::LIST_BRANCH_BASE_URL + page_num.to_s + "&per_page=#{StaleBranchConstant::BRANCH_PER_PAGE}"
    HTTParty.get(list_branch_url, headers: StaleBranchConstant::HEADERS)
  end

  # Returns the branch report and the author report
  def list_all_branches
    page_num = 1
    branch_report = []
    author = {}
    current_branches = list_branches(1)
    while current_branches.any?
      puts "In Progress List Branch Page # #{page_num}"
      current_branches.each do |branch|
        com_det = HTTParty.get(branch['commit']['url'], headers: StaleBranchConstant::HEADERS)
        committer = com_det['commit']['committer']
        branch_report << {
          name: branch['name'],
          c_date: committer['date'],
          c_name: committer['name'],
          c_email: committer['email']
        }
        author[committer['name']] = author.key?(committer['name']) ? (author[committer['name']] + 1) : 1
      end
      page_num += 1
      current_branches = list_branches(page_num)
      puts current_branches
    end
    { 'b_r': branch_report, 'a_r': author }
  end


  def branches_report_per_page(page_num = 1)
    branch_report = []
    list_branch_url = StaleBranchConstant::LIST_BRANCH_BASE_URL + page_num.to_s + "&per_page=#{StaleBranchConstant::BRANCH_PER_PAGE}"
    current_branches = HTTParty.get(list_branch_url, headers: StaleBranchConstant::HEADERS)
    current_branches.each do |branch|
      com_det = HTTParty.get(branch['commit']['url'], headers: StaleBranchConstant::HEADERS)
      committer = com_det['commit']['committer']
      branch_report << {
        name: branch['name'],
        c_date: committer['date'],
        c_name: committer['name'],
        c_email: committer['email']
      }
    end
    { 'b_r': branch_report }  
  end
end
