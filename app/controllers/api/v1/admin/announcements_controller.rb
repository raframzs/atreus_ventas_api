module Api
  module V1
    module Admin
      class AnnouncementsController < ApplicationController
        before_action :require_super_admin!

        # GET /api/v1/admin/announcement
        def show
          announcement = Announcement.order(updated_at: :desc).first
          render json: announcement ? announcement_json(announcement) : nil
        end

        # POST /api/v1/admin/announcement
        def create
          # Solo uno activo a la vez
          Announcement.update_all(active: false) if announcement_params[:active] == true || announcement_params[:active] == "true"

          announcement = Announcement.order(updated_at: :desc).first_or_initialize
          announcement.assign_attributes(announcement_params)

          if announcement.save
            render json: announcement_json(announcement)
          else
            render json: { errors: announcement.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/announcement
        def update
          announcement = Announcement.order(updated_at: :desc).first
          return render json: { error: "No hay anuncio" }, status: :not_found unless announcement

          Announcement.update_all(active: false) if announcement_params[:active] == true || announcement_params[:active] == "true"

          if announcement.update(announcement_params)
            render json: announcement_json(announcement)
          else
            render json: { errors: announcement.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def announcement_params
          params.require(:announcement).permit(:title, :body, :kind, :active)
        end

        def announcement_json(a)
          {
            id:         a.id,
            title:      a.title,
            body:       a.body,
            kind:       a.kind,
            active:     a.active,
            updated_at: a.updated_at
          }
        end
      end
    end
  end
end
