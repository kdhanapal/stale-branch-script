# frozen_string_literal: true

module StaleBranchConstant
  HEADERS = {
    'Accept' => 'application/vnd.github.v3+json',
    'Authorization' => 'token <your personal access token here>'
  }.freeze
  OWNER = 'freshdesk'
  CREATE_RESPONSE_CODE = 201
  UPDATE_PR_RESPONSE_CODE = 200
  REPO = 'freshsales'
  OPEN_PR_STATE = 'open'
  EXCLUDED_BRANCHES = %w[main staging master].freeze
  MASTER_BRANCH = 'staging'
  WHITELISTED_BRANCH_SUFFIX = '-whitelist'
  PR_TITLE = 'Standard PR Created for Deleting Branch'
  PR_BODY = 'This PR is an automated one created just for'\
         ' closing and then deleting the branch.'\
         ' For any queries, please contact the respective code owners'
  POST_BASE_URL = "https://api.github.com/repos/#{OWNER}/#{REPO}/pulls"
  PATCH_PR_BASE_URL = "https://api.github.com/repos/#{OWNER}/#{REPO}/pulls/"
  OPEN_PR_URL = "https://api.github.com/repos/#{OWNER}/#{REPO}/"\
                "pulls?state=#{OPEN_PR_STATE}&page="
  PATCH_BODY = { state: 'closed' }.to_json
  DELETE_BRANCH_BASE_URL = 'https://api.github.com/repos/'\
                           "#{OWNER}/#{REPO}/git/refs/heads/"
  STALE_BRANCH_TIME_UNIT_VALUE = 8
  TIME_DIFFERENCE_UNIT = 'in_months'
  UTC_CURRENT_TIMESTAMP = Time.now.utc.iso8601
  BRANCH_PER_PAGE = 100
  LIST_BRANCH_BASE_URL = 'https://api.github.com/repos/'\
                          "#{OWNER}/#{REPO}/branches?page="
end
