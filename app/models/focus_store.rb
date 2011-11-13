class FocusStore < ActiveRecord::Base
  serialize :focus, Focus::Focus
end
