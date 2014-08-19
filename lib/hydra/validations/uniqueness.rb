require 'hydra/validations'
require 'hydra/validations/cardinality'

module Hydra
  module Validations
    #
    # UniquenessValidator - an ActiveFedora model validator
    #
    # Usage:
    #
    #   validates :field, uniqueness: { solr_name: "field_ssim" }
    #   validates_uniqueness_of :field, solr_name: "field_ssim"
    #
    # Restrictions:
    #
    # - Accepts only one attribute (can have more than one UniquenessValidator on a model, however)
    # - :solr_name option must be present
    # - Can be used on enumerable values (attribute defined with :multiple=>true option), but 
    #   validator also validates single cardinality, so will not pass validation if enumerable
    #   has more than one member.
    #
    # CAVEAT: The determination of uniqueness depends on a Solr query.
    # False negatives (record invalid) may result if, for example,
    # querying a Solr field of type "text".
    #
    class UniquenessValidator < ActiveModel::EachValidator

      include Cardinality

      def check_validity!
        raise ArgumentError, "UniquenessValidator accepts only a single attribute: #{attribues}" if attributes.length > 1 
        raise ArgumentError, "UniquenessValidator requires the :solr_name option be present." unless options[:solr_name].present?
      end

      def validate_each(record, attribute, value)
        # TODO: i18n messages
        validate_cardinality(:single, record, attribute, value)
        # Validate uniqueness proper only if value is of single cardinality
        return if record.errors.added?(attribute, "can't have more than one value") 
        value = value.first if value.respond_to?(:each)
        conditions = {options[:solr_name] => value}
        conditions.merge!("-id" => record.id) if record.persisted?
        record.errors.add attribute, "has already been taken" if record.class.exists?(conditions)
      end

    end

    module HelperMethods
      def validates_uniqueness_of *attr_names
        validates_with UniquenessValidator, _merge_attributes(attr_names)
      end
    end
  end
end