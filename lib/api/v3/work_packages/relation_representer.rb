#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/representer/json/hal'

module API
  module V3
    module WorkPackages
      class RelationRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        def initialize(model, options = {}, *expand)
          @current_user = options[:current_user]
          @work_package = options[:work_package]
          @expand = expand

          super(model)
        end

        property :_type, exec_context: :decorator

        link :self do
          { href: "#{root_path}api/v3/relations/#{represented.model.id}" }
        end

        link :relatedFrom do
          { href: "#{root_path}api/v3/work_packages/#{represented.model.from_id}" }
        end

        link :relatedTo do
          { href: "#{root_path}api/v3/work_packages/#{represented.model.to_id}" }
        end

        link :remove do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.from.id}/relations/#{represented.model.id}",
            method: :delete,
            title: 'Remove relation'
          } if current_user_allowed_to(:manage_work_package_relations)
        end

        property :delay, getter: -> (*) { model.delay }, render_nil: true, if: -> (*) { model.relation_type == 'precedes' }

        def _type
          "Relation::#{relation_type}"
        end

        private

        def current_user_allowed_to(permission)
          @current_user && @current_user.allowed_to?(permission, represented.model.from.project)
        end

        def relation_type
          relation = represented.model
          relation.relation_type_for(@work_package).camelize
        end
      end
    end
  end
end
