
import Foundation

enum ChatState: Equatable {
  case idle
  case typing
  case thinking
  case streaming
  case speaking
  case error(String)
}
