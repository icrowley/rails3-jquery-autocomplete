module Rails3JQueryAutocomplete
  module Orm
    module ActiveRecord
      def get_autocomplete_order(methods, options, model=nil)
        order = options[:order]

        table_prefix = model ? "#{model.table_name}." : ""
        order || methods.map { |m| "#{table_prefix}#{m} ASC" }.join(', ')
      end

      def get_autocomplete_items(parameters)
        model   = parameters[:model]
        term    = parameters[:term]
        methods = parameters[:methods]
        options = parameters[:options]
        scopes  = Array(options[:scopes])
        where   = options[:where]
        limit   = get_autocomplete_limit(options)
        order   = get_autocomplete_order(methods, options, model)


        items = model.scoped

        scopes.each { |scope| items = items.send(scope) } unless scopes.empty?

        items = items.select(get_autocomplete_select_clause(model, methods, options)) unless options[:full_model]
        items = items.where(get_autocomplete_where_clause(model, term, methods, options)).
            limit(limit).order(order)
        items = items.where(where) unless where.blank?

        items
      end

      def get_autocomplete_select_clause(model, methods, options)
        table_name = model.table_name
        (["#{table_name}.#{model.primary_key}", methods.map { |m| "#{table_name}.#{m}" }.join(', ')] + (options[:extra_data].blank? ? [] : options[:extra_data]))
      end

      def get_autocomplete_where_clause(model, term, methods, options)
        table_name = model.table_name
        is_full_search = options[:full]
        like_clause = (postgres?(model) ? 'ILIKE' : 'LIKE')
        where = if methods.size == 1
            ["LOWER(#{table_name}.#{methods[0]})"]
          else
            ["LOWER(CONCAT_WS(' ', #{methods.map { |m| "#{table_name}.#{m}" }.join(', ')}))"]
          end
        where[0] << "#{like_clause} ?"
        where    << "#{(is_full_search ? '%' : '')}#{term.downcase}%"
      end

      def postgres?(model)
        # Figure out if this particular model uses the PostgreSQL adapter
        model.connection.class.to_s.match(/PostgreSQLAdapter/)
      end
    end
  end
end
