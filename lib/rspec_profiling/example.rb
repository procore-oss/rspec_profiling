require "benchmark"
require "rspec_profiling/vcs/git"
require "rspec_profiling/vcs/svn"
require "rspec_profiling/vcs/git_svn"
require "rspec_profiling/collectors/csv"
require "rspec_profiling/collectors/json"

module RspecProfiling
  class Example
    IGNORED_QUERIES_PATTERN = %r{(
      pg_table|
      pg_attribute|
      pg_namespace|
      show\stables|
      pragma|
      sqlite_master/rollback|
      ^TRUNCATE TABLE|
      ^ALTER TABLE|
      ^BEGIN|
      ^COMMIT|
      ^ROLLBACK|
      ^RELEASE|
      ^SAVEPOINT
    )}xi

    def initialize(example)
      @example = example
      @counts  = Hash.new(0)
      @event_counts = Hash.new(0)
      @event_times = Hash.new(0)
      @event_events = Hash.new()
    end

    def file
      metadata[:file_path]
    end

    def line_number
      metadata[:line_number]
    end

    def description
      metadata[:full_description]
    end

    def status
      execution_result.status
    end

    def exception
      execution_result.exception
    end

    def time
      execution_result.run_time
    end

    def owner_tag
      ownership_for_file(metadata[:file_path])
    end

    def query_count
      counts[:query_count]
    end

    def query_time
      counts[:query_time]
    end

    def request_count
      counts[:request_count]
    end

    def request_time
      counts[:request_time]
    end

    attr_reader :event_counts, :event_times, :event_events

    def log_query(query, start, finish)
      unless query[:sql] =~ IGNORED_QUERIES_PATTERN
        counts[:query_count] += 1
        counts[:query_time] += (finish - start)
      end
    end

    def log_request(request, start, finish)
      counts[:request_count] += 1
      counts[:request_time] += request[:view_runtime].to_f
    end

    def log_event(event_name, event, start, finish)
      event_counts[event_name] += 1
      event_times[event_name] += (finish - start)
      event_events[event_name] ||= []
      if verbose_record_event?(event_name)
        begin
          event_events[event_name] << event.as_json
        rescue => e
          # no op
        end
      end
    end

    private

    attr_reader :example, :counts

    def execution_result
      @execution_result ||= begin
        result = example.execution_result
        result = OpenStruct.new(result) if result.is_a?(Hash)
        result
      end
    end

    def metadata
      example.metadata
    end

    def verbose_record_event?(event_name)
      metadata[:record_events].to_a.include?(event_name)
    end

    def ownership_for_file(file_path)
      return nil if RspecProfiling.config.magic_comment.empty?
      ownership_regex = /(^#\s*#{RspecProfiling.config.magic_comment}:\s*)\K(?<#{RspecProfiling.config.magic_comment}>.*$)/.freeze
      comments = top_comments_from_file(file_path)
      matching_line = comments.detect { |line| line.match?(ownership_regex) }
      extract_ownership(matching_line, ownership_regex) if matching_line
    end

    def top_comments_from_file(file_path)
      with_file(file_path) do |f|
        f.take_while { |line| line.start_with?('#', "\n") }
      end
    end

    def with_file(file_path)
      if File.exist?(file_path)
        File.open(file_path)
      else
        puts "File not found: #{file_path}"
        []
      end
    end

    def extract_ownership(matching_line, regex)
      matching_line.match(regex)[RspecProfiling.config.magic_comment.to_sym]
    end
  end
end
