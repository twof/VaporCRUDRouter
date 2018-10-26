public enum OnlyExceptEither<ControllerMethod> {
    case only([ControllerMethod])
    case except([ControllerMethod])
}
