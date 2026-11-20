package com.micorlov.blackjack21_v2.extras;

import android.app.Activity;
import android.os.CancellationSignal;
import android.util.Log;

import androidx.credentials.Credential;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialCancellationException;
import androidx.credentials.exceptions.GetCredentialException;

import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;

/**
 * Google's account picker (Credential Manager) for a Google ID token, which FirebaseSocialService turns into a Firebase
 * credential. The audience is the project's web OAuth client, which the Firebase plugin writes into the
 * default_web_client_id string resource from google-services.json.
 */
public final class GoogleIdToken {
    /** Exactly one call per request: a token, or null and "canceled" / "failed" / another short reason. */
    public interface Callback {
        void onResult(String idToken, String error);
    }

    private static final String TAG = "BJGoogleSignIn";

    private GoogleIdToken() {}

    public static void request(Activity activity, Callback callback) {
        int res = activity.getResources().getIdentifier("default_web_client_id", "string", activity.getPackageName());
        if (res == 0) {
            Log.w(TAG, "default_web_client_id missing: is google-services.json in the build?");
            callback.onResult(null, "no_web_client_id");
            return;
        }
        GetCredentialRequest request = new GetCredentialRequest.Builder()
                .addCredentialOption(new GetSignInWithGoogleOption.Builder(activity.getString(res)).build())
                .build();
        CredentialManager.create(activity).getCredentialAsync(activity, request, new CancellationSignal(), Runnable::run,
                new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                    @Override
                    public void onResult(GetCredentialResponse response) {
                        Credential credential = response.getCredential();
                        if (!(credential instanceof CustomCredential)
                                || !GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL.equals(credential.getType())) {
                            Log.w(TAG, "unexpected credential type " + credential.getType());
                            callback.onResult(null, "unexpected_credential");
                            return;
                        }
                        try {
                            callback.onResult(GoogleIdTokenCredential.createFrom(credential.getData()).getIdToken(), null);
                        } catch (Exception e) {
                            Log.w(TAG, "could not read the Google ID token", e);
                            callback.onResult(null, "bad_token");
                        }
                    }

                    @Override
                    public void onError(GetCredentialException e) {
                        Log.w(TAG, "getCredential failed: " + e.getType() + ": " + e.getMessage());
                        callback.onResult(null, e instanceof GetCredentialCancellationException ? "canceled" : "failed");
                    }
                });
    }
}
