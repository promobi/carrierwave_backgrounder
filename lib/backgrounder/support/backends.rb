module CarrierWave
  module Backgrounder
    module Support
      module Backends

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          attr_reader :queue_options

          def backend(queue_name=nil, args={})
            return @backend if @backend
            @queue_options = args
            @backend = queue_name
          end

          def enqueue_for_backend(worker, class_name, subject_id, mounted_as)
            self.send :"enqueue_#{backend}", worker, class_name, subject_id, mounted_as
          end

          private

          def enqueue_active_job(worker, *args)
            worker.perform_later(*args.map(&:to_s))
          end

          def enqueue_sidekiq(worker, *args)
            override_queue_name = worker.sidekiq_options['queue'] == 'default' || worker.sidekiq_options['queue'].nil?
            args = sidekiq_queue_options(override_queue_name, 'class' => worker, 'args' => args.map(&:to_s))
            worker.client_push(args)
          end

          private

          def sidekiq_queue_options(override_queue_name, args)
            if override_queue_name && queue_options[:queue]
              args['queue'] = queue_options[:queue]
            end
            args['retry'] = queue_options[:retry] unless queue_options[:retry].nil?
            args['timeout'] = queue_options[:timeout] if queue_options[:timeout]
            args['backtrace'] = queue_options[:backtrace] if queue_options[:backtrace]
            args
          end
        end
      end
    end
  end
end
