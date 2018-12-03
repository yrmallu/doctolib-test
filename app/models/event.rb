class Event < ApplicationRecord
  SLOT_DURATION = 30.minutes.freeze
  SLOT_TIME_FORMAT = '%-k:%M'.freeze
  AVAILABILITY_DAYS = 7

  KINDS = [
    OPENING_KIND = 'opening'.freeze,
    APPOINTMENT_KIND = 'appointment'.freeze
  ].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  validate :opening_uniques
  validate :appointment_bookability

  scope :openings, -> { where(kind: OPENING_KIND) }
  scope :appointments, -> { where(kind: APPOINTMENT_KIND) }
  scope :for_date, ->(date) { where(<<-SQL, date: date) }
    date(starts_at) = date(:date)
      OR weekly_recurring = 1
     AND strftime('%w', starts_at) = strftime('%w', :date)
     AND date(starts_at) <= date(:date)
  SQL

  class << self
    def availabilities(date)
      AVAILABILITY_DAYS.times.map do |index|
        next_date = date.to_date + index
        { date: next_date, slots: available_slots(next_date) }
      end
    end

    def available_slots(date)
      events = for_date(date)
      openings = events.select(&:opening?).flat_map(&:slots)
      appointments = events.select(&:appointment?).flat_map(&:slots)

      openings - appointments
    end
  end

  def opening?
    kind == OPENING_KIND
  end

  def appointment?
    kind == APPOINTMENT_KIND
  end

  def slots
    (starts_at.to_i...ends_at.to_i).step(SLOT_DURATION).map do |seconds|
      Time.zone.at(seconds).strftime(SLOT_TIME_FORMAT)
    end
  end

  private

  def opening_uniques
    return unless opening? && starts_at.present? && ends_at.present? && opening_exists?
    errors[:base] << "opening is already exist"
  end

  def appointment_bookability
    return unless appointment? && starts_at.present? && ends_at.present?
    return if appointment_bookable?
    errors[:base] << "appointment is not bookable"
  end

  def opening_exists?
    self.class.openings.exists?(starts_at: starts_at, ends_at: ends_at)
  end

  def appointment_bookable?
    (slots - self.class.available_slots(starts_at.to_date)).blank?
  end
end
