# frozen_string_literal: true

module Smartcaptcha
  module Adapters
    module ControllerMethods

    private

      def verify_smartcaptcha(options = {})
        return true if Smartcaptcha.skip_env?

        model = options[:model]
        attribute = options.fetch(:attribute, :base)
        options[:host] = request.host unless options.key?(:host)
        options[:ip] = request.remote_ip
        smartcaptcha_response = options[:response] || smartcaptcha_response_token(options[:action])
        verified = Smartcaptcha.verify_via_api_call(smartcaptcha_response, options)
        unless verified
          smartcaptcha_error(
            model,
            attribute,
            options.fetch(:message) { Smartcaptcha.error_message(:verification_failed) }
          )
        end
        verified
      end

      def smartcaptcha_response_token(action = nil)
        response_param = params['smart-token']
        if response_param&.respond_to?(:to_h)
          response_param[action].to_s
        else
          response_param.to_s
        end
      end

      def smartcaptcha_error(model, attribute, message)
        if model
          model.errors.add(attribute, message)
        elsif smartcaptcha_flash_supported?
          flash[:smartcaptcha_error] = message
        end
      end

      def smartcaptcha_flash_supported?
        request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
      end
    end
  end
end
