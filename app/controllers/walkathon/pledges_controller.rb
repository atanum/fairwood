class Walkathon::PledgesController < ApplicationController
  before_action :set_walkathon_pledge, only: [:show, :edit, :update, :destroy]

  # GET /walkathon/pledges
  # GET /walkathon/pledges.json
  def index
    @walkathon_pledges = Walkathon::Pledge.includes(:student)

    respond_to do |format|
      format.html
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"pledges.csv\""
        headers['Content-Type']        ||= 'text/csv'
      end
    end
  end

  # GET /walkathon/pledges/1
  # GET /walkathon/pledges/1.json
  def show
  end

  # GET /walkathon/pledges/new
  def new
    @walkathon_pledge = Walkathon::Pledge.new
  end

  # GET /walkathon/pledges/1/edit
  def edit
  end

  # POST /walkathon/pledges
  # POST /walkathon/pledges.json
  def create
    student = Student.where("full_name ilike ?", params[:walkathon_pledge][:student_name]).first rescue nil
    @walkathon_pledge =
      Walkathon::Pledge.where(student: student, sponsor_name: params[:walkathon_pledge][:sponsor_name]).first rescue nil if student

    # There was an old pledge. Delete it.
    @walkathon_pledge.delete if @walkathon_pledge

    @walkathon_pledge         = Walkathon::Pledge.new(
      params[:walkathon_pledge][:pledge_type] == 'fixed' ? fixed_params : per_lap_params
    )
    @walkathon_pledge.student = student

    lap_record                  = Walkathon::LapCount.find_by_student_id(student.id) if student
    @walkathon_pledge.lap_count = lap_record.lap_count if lap_record

    respond_to do |format|
      if @walkathon_pledge.save
        UserMailer.new_pledge_email(student).deliver
        format.html { redirect_to :thankyou, notice: 'Pledge was successfully created.' }
        format.json { render :show, status: :created, location: @walkathon_pledge }
      else
        format.html { render :new }
        format.json { render json: @walkathon_pledge.errors, status: :unprocessable_entity }
      end
    end
  end

  def thankyou
    # Show thank you page.
  end

  def record_laps
    # Record lap info for upto 10 students
    update_count = 0
    errors       = []
    Walkathon::Pledge.transaction do
      params[:row].keys.sort.each do |row_num|
        student_name = params[:row][row_num][:student_name]
        if student_name.present?
          student = Student.where("full_name ilike ?", student_name).first rescue nil
          unless student
            errors << "student #{student_name} not found"
            next
          end

          # We found the student. Load up all of his/her pledges and update them.
          Walkathon::Pledge.where(student: student).each do |pledge|
            pledge.lap_count = params[:row][row_num][:lap_count]
            if pledge.save
              update_count += 1
            else
              # Store the validation error on this row's lap count
              errors << "student #{student_name} lap-count is invalid: #{pledge.errors[:lap_count]}"
            end
          end

          # Also add/update his lap record
          lap_record           = Walkathon::LapCount.find_by_student_id(student.id) || Walkathon::LapCount.new(student: student)
          lap_record.lap_count = params[:row][row_num][:lap_count]
          lap_record.save
        end
      end
      raise ActiveRecord::Rollback, "Failed validation" if errors.length > 0
    end

    if errors.length == 0
      redirect_to show_record_laps_url, notice: "Updated #{update_count} pledges"
    else
      flash[:errors]    = errors
      flash[:prev_rows] = params[:row]
      redirect_to show_record_laps_url
    end
  end

  def show_record_laps
    # Show the record-laps form
    @prev_rows = flash[:prev_rows]
    @errors    = flash[:errors]
  end

  def summary
    @pledge_summaries = Walkathon::Pledge.joins(student: :teacher).select(
      'students.full_name, students.grade, ' +
        'concat(teachers.title, \' \', teachers.last_name) as teacher_name, ' +
        'min(walkathon_pledges.lap_count) as lap_count, ' +
        'sum(walkathon_pledges.committed_amount) as total_committed_amount, ' +
        'sum(walkathon_pledges.paid_amount) as total_paid_amount').group(
      'students.full_name, students.grade, teacher_name')

    respond_to do |format|
      format.html
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"pledge-summaries.csv\""
        headers['Content-Type']        ||= 'text/csv'
      end
    end
  end

  # PATCH/PUT /walkathon/pledges/1
  # PATCH/PUT /walkathon/pledges/1.json
  def update
    respond_to do |format|
      if @walkathon_pledge.update(walkathon_pledge_params)
        format.html { redirect_to @walkathon_pledge, notice: 'Pledge was successfully updated.' }
        format.json { render :show, status: :ok, location: @walkathon_pledge }
      else
        format.html { render :edit }
        format.json { render json: @walkathon_pledge.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /walkathon/pledges/1
  # DELETE /walkathon/pledges/1.json
  def destroy
    @walkathon_pledge.destroy
    respond_to do |format|
      format.html { redirect_to walkathon_pledges_url, notice: 'Pledge was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_walkathon_pledge
    @walkathon_pledge = Walkathon::Pledge.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def fixed_params
    params.require(:walkathon_pledge).permit(:student_name, :sponsor_name, :sponsor_phone, :sponsor_email, :pledge_type, :fixed_pledge)
  end

  def per_lap_params
    params.require(:walkathon_pledge).permit(:student_name, :sponsor_name, :sponsor_phone, :sponsor_email, :pledge_type, :pledge_per_lap, :maximum_pledge)
  end
end
