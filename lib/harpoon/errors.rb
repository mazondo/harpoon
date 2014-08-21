module Harpoon
  module Errors
    class InvalidConfigLocation < StandardError;end;
    class AlreadyInitialized < StandardError;end;
    class InvalidConfiguration < StandardError;end;
    class MissingSetup < StandardError;end;
  end
end
