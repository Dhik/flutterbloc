import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterapi/model/data_model.dart';
import 'package:flutterapi/repository/auth_repository.dart';
import 'package:flutterapi/event/auth_event.dart';
import 'package:flutterapi/state/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({this.authRepository}) : assert(authRepository != null), super(null);
  AuthState get initialState => AuthInit();

  @override
  Stream<AuthState> mapEventToState(AuthEvent event) async* {
    if(event is AuthCheck) {
      yield AuthLoading();

      final hasToken=await authRepository.hasToken();
      if(hasToken != null){
        yield AuthHasToken(token: hasToken);
      }else{
        yield AuthFailed();
      }
    }
    if(event is GetDataWithToken){
      yield AuthLoading();

      final user = await authRepository.getData(event.token);
      yield AuthData(email: user.email, name: user.name);
    }
    if(event is LoginProcess){
      yield AuthLoading();
      try{
        final login = await authRepository.loginUser(event.email, event.password, "Mobile Sanctum");
        if(login.message != "failed"){
          yield LoginSuccess();
          await authRepository.setLocalToken(login.data.token);
          yield AuthHasToken(token: login.data.token); 
        }
      }catch(e){
        yield LoginFailed("Login Gagal");
      }
    }
    if(event is LoggedOut) {
      final String token = await authRepository.hasToken();
      try{
        final Logout logout = await authRepository.userLogout(token);
        if(logout.message == "success") {
          await authRepository.unsetLocalToken();
          yield AuthFailed();
        }
      } catch(e) {}
    }
  }
}