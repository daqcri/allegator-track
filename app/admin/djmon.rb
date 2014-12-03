ActiveAdmin.register_page "Delayed Job Monitoring" do
  content do
    iframe style: "width: 100%; height: 100vh;", src: '/admin/djmon/overview' do
    end
  end
end