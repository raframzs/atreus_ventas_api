module Api
  module V1
    class AnnouncementsController < ApplicationController
      # GET /api/v1/announcement
      def show
        announcement = Announcement.current
        if announcement
          render json: announcement_json(announcement)
        else
          render json: nil
        end
      end

      private

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
