module RspecProfiling
  def self.configure
    yield config
  end

  def self.config
    @config ||= OpenStruct.new({
      collector:  RspecProfiling::Collectors::CSV,
      vcs:        RspecProfiling::VCS::Git,
      table_name: 'spec_profiling_results',
      events:     [],
      magic_comment: 'team',
      additional_data: {}
    })
  end
end
