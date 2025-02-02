require 'rails/generators/base'

module Gql
  module GqlGeneratorBase
    protected

    # Generate a namedspaced class name with the mutation prefix
    def prefixed_class_name(prefix)
      (class_path + ["#{prefix}_#{file_name}"]).map!(&:camelize).join("::")
    end

    def type_map
      {
        integer: 'Int',
        string: 'String',
        boolean: 'Boolean',
        decimal: 'Float',
        datetime: 'GraphQL::Types::ISO8601DateTime',
        date: 'GraphQL::Types::ISO8601Date',
        hstore: 'GraphQL::Types::JSON',
        text: 'String',
        json: 'GraphQL::Types::JSON',
        jsonb: 'GraphQL::Types::JSON'
      }
    end

    def map_model_types(model_name)
      klass = model_name.constantize
      associations = klass.reflect_on_all_associations(:belongs_to)
      bt_columns = associations.map(&:foreign_key)

      klass.columns
        .reject { |col| bt_columns.include?(col.name) }
        .reject { |col| type_map[col.type].nil? }
        .map do |col|
          {
            name: col.name,
            null: col.null,
            gql_type: klass.primary_key == col.name ? 'GraphQL::Types::ID' : type_map[col.type]
          }
        end
    end

    def filter_names(fields)
      puts "filter_names is running"
      fields.each do |field|
        # TODO: probably better to map this and use a loop
        if field[:name] == "book_id"
          # Change the name to "book" and the type to "Book"
          field[:name] = "book"
          field[:gql_type] = "Types::Book"
        elsif field[:name] == "user_id"
          # Do the same thing for user as we did for book
          field[:name] = "user"
          field[:gql_type] = "Types::User"
        elsif field[:name].end_with?("_id")
          # This will be the general case
          # TODO: write the general case
        end
      end
    end

    def root_directory(namespace)
      "app/graphql/#{namespace.underscore}"
    end

    def wrap_in_namespace(namespace)
      namespace = namespace.split('::')
      namespace.shift if namespace[0].empty?

      code = namespace.each_with_index.map { |name, i| "  " * i + "module #{name}" }.join("\n")
      code << "\n" << yield(namespace.size) << "\n"
      code << (namespace.size - 1).downto(0).map { |i| "  " * i  + "end" }.join("\n")
      code
    end

    def class_with_fields(namespace, name, superclass, fields)
      puts "class_with_fields is running"
      filter_names(fields)
      wrap_in_namespace(namespace) do |indent|
        klass = []
        
        klass << sprintf("%sclass %s < %s", "  " * indent, name, superclass)
        klass << sprintf("%sdescription \"This description is a placeholder for better things to come\"", "  " * (indent + 1))

        fields.each do |field|
          klass << sprintf("%sfield :%s, %s, null: %s #TEST", "  " * (indent + 1), field[:name], field[:gql_type], field[:null])
        end

        klass << sprintf("%send", "  " * indent)
        klass.join("\n")
      end
    end
  end
end
