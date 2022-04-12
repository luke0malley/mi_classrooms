# == Schema Information
#
# Table name: rooms
#
#  building_bldrecnbr          :bigint           not null
#  characteristics             :text             default([]), is an Array
#  dept_description            :string
#  dept_grp                    :string
#  facility_code_heprod        :string
#  floor                       :string
#  instructional_seating_count :integer
#  rmrecnbr                    :bigint           not null, primary key
#  rmtyp_description           :string
#  room_number                 :string
#  square_feet                 :integer
#  tsv                         :tsvector
#  visible                     :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  dept_id                     :integer
#
# Indexes
#
#  index_rooms_on_building_bldrecnbr  (building_bldrecnbr)
#  index_rooms_on_tsv                 (tsv) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (building_bldrecnbr => buildings.bldrecnbr)
#
class Room < ApplicationRecord
  include PgSearch::Model
  self.primary_key = 'rmrecnbr'
  extend OrderAsSpecified
  

  belongs_to :building, foreign_key: :building_bldrecnbr
  belongs_to :campus_record, optional: true
  has_many :room_characteristics, foreign_key: :rmrecnbr, dependent: :destroy
  has_one :room_contact, foreign_key: :rmrecnbr, dependent: :destroy
  has_one_attached :room_panorama
  has_one_attached :room_image
  has_one_attached :room_layout
  has_many :notes, as: :noteable

  multisearchable(
    against: [:rmrecnbr, :room_number, :building_bldrecnbr],
    update_if: :updated_at_changed?
  )

  pg_search_scope(
    :with_classroom_name,
    against: { 
      facility_code_heprod: 'A',
      nickname: 'B'},
    using: {
      tsearch: {
        dictionary: "english",
        prefix: true,
        any_word: false,

      }
    }
  )

  pg_search_scope(
    :with_building_name,
    associated_against: {
      building: {name: 'A',
      nick_name: 'B',
      abbreviation: 'C'}
    },
    using: {
      tsearch: {
        dictionary: "simple",
        prefix: true,
        any_word: false

      }
    }
  )


  pg_search_scope(
    :with_all_characteristics,
    against: [:characteristics],
    using: {
      tsearch:{
        dictionary: "simple",
        prefix: false,
        any_word: false,
      }
    }
  )

  pg_search_scope(
    :with_school_or_college_name,
    against: [:dept_group_description],
    using: {
      tsearch:{
        dictionary: "english",
        prefix: true,
        any_word: false,
      }
    }
  )

  scope :classrooms, -> {
    where(rmtyp_description: ["Classroom"], visible: true).where.not(facility_code_heprod: nil).where('instructional_seating_count > ?', 1)
  }

  scope :classrooms_not_visible, -> {
    where(rmtyp_description: ["Classroom"], visible: false).where.not(facility_code_heprod: nil).where('instructional_seating_count > ?', 1)
  }

  scope :classroom_labs, -> {
  where(rmtyp_description: ["Class Laboratory"])
  }

scope :classrooms_including_labs, -> {
  where(rmtyp_description: ["Classroom", "Class Laboratory"])
}

def display_name
  if self.nickname.present?
    "#{self.facility_code_heprod} - #{self.nickname}"
  else
    "#{self.facility_code_heprod}"
  end
end

end