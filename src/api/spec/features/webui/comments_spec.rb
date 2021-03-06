require "browser_helper"

RSpec.feature "Comments", :type => :feature, :js => true do
  let(:user) { create(:confirmed_user, login: "burdenski") }

  scenario 'can be created' do
    login user
    visit project_show_path(user.home_project)
    fill_in 'body', with: 'Comment Body'
    find_button('Add comment').click

    expect(page).to have_css("#flash-messages", text: 'Comment was successfully created.')
    expect(page).to have_text('Comment Body')
  end

  scenario 'can be answered' do
    login user
    comment = create(:comment_project, project: Project.first, user: user)
    visit project_show_path(user.home_project)
    page.execute_script("$('#reply_form_of_#{comment.id}').show();")
    fill_in "reply_body_#{comment.id}", with: 'Reply Body'
    click_button("add_reply_#{comment.id}")

    expect(page).to have_css("#flash-messages", text: 'Comment was successfully created.')
    expect(page).to have_text('Reply Body')
  end
end
