module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements

      # Attempts to add a foreign key using ANSI SQL Standard syntax,
      # so most database providers should work just fine.
      #
      # ===Params
      # * table_name - the name of the database table being altered
      # * foreign_key - name of foreign key column or an array of fk column names
      # * references - name of primary key column or an array of pk column names
      # * options - hash of additional options accepted options: * :name - name of
      #   constraint * :on_update - referential action to take (CASCADE, RESTRICT, NO
      #   ACTION, SET NULL, SET DEFAULT) * :on_delete - referential action to take
      #   (CASCADE, RESTRICT, NO ACTION, SET NULL, SET DEFAULT)
      def add_foreign_key(table_name, foreign_key, references, options={})
        prep_args(table_name, foreign_key, references, options) do |t, f, r, o|
          table_name = t
          foreign_key = f
          references = r
          options = o
        end

        query = "ALTER TABLE [#{table_name}] "
        constraint_name = get_constraint_name(table_name, foreign_key, references, options)
        query << "ADD CONSTRAINT [#{constraint_name}] "
        query << "FOREIGN KEY ("
        if foreign_key.is_a?(Array)
          query << "[#{foreign_key.join("],[")}] "
        else
          query << "[#{foreign_key}] "
        end
        query << ") REFERENCES "
        if references.is_a?(Array)
          query << "[#{references.join("],[")}] "
        else
          query << "[#{references}] "
        end
        query << "ON UPDATE #{options[:on_update]} " if options[:on_update]
        query << "ON DELETE #{options[:on_delete]} " if options[:on_delete]

        execute(query)
      rescue
        if respond_to?(:puts_migration_error)
          puts_migration_error($!)
        else
          raise
        end
      end

      # Attempts to remove a foreign key using ANSI SQL Standard syntax,
      # so most database providers should work just fine.
      #
      # ===Params
      # * table_name - the name of the database table being altered
      # * foreign_key - name of foreign key column or an array of fk column names
      # * references - name of primary key column or an array of pk column names
      # * options - hash of additional options accepted options: * :name - name of
      #   constraint * :on_update - referential action to take (CASCADE, RESTRICT, NO
      #   ACTION, SET NULL, SET DEFAULT) * :on_delete - referential action to take
      #   (CASCADE, RESTRICT, NO ACTION, SET NULL, SET DEFAULT)
      def remove_foreign_key(table_name, foreign_key, references, options={})
        prep_args(table_name, foreign_key, references, options) do |t, f, r, o|
          table_name = t
          foreign_key = f
          references = r
          options = o
        end

        constraint_name = get_constraint_name(table_name, foreign_key, references, options)
        query = "ALTER TABLE [#{table_name}] DROP CONSTRAINT [#{constraint_name}]"
        begin
          execute(query)
        rescue
          query = "ALTER TABLE [#{table_name}] DROP FOREIGN KEY [#{constraint_name}]"
          execute(query)
        end
      rescue
        if respond_to?(:puts_migration_error)
          puts_migration_error($!)
        else
          raise
        end
      end

      private

      # Prepares the arguments for use and yields them back.
      def prep_args(table_name, foreign_key, references, options={})
        table_name = table_name.to_s
        foreign_key = foreign_key.to_s if foreign_key.is_a?(Symbol)
        references = references.to_s if references.is_a?(Symbol)
        foreign_key.collect! {|x| x.to_s } if foreign_key.is_a?(Array)
        references.collect! {|x| x.to_s } if references.is_a?(Array)
        yield(table_name, foreign_key, references, options)
      end

      # Gets the constraint name based on the options.
      def get_constraint_name(table_name, foreign_key, references, options={})
        constraint_name = options[:name]
        unless constraint_name
          constraint_name = String.new(table_name) # create a copy of table_name so its not modified
          constraint_name << "_" + foreign_key if foreign_key.is_a?(String)
          constraint_name << "_" + foreign_key.join("_") if foreign_key.is_a?(Array)
          constraint_name << "_" + references if references.is_a?(String)
          constraint_name << "_" + references.join("_") if references.is_a?(Array)
          constraint_name = constraint_name[0, 64] if constraint_name.length > 64
        end
        constraint_name
      end

    end
  end
end

