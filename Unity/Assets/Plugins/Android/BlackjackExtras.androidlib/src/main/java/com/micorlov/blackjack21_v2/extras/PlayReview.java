package com.micorlov.blackjack21_v2.extras;

import android.app.Activity;
import android.util.Log;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;

/**
 * Google Play's native in-app review card (com.google.android.play:review). Play decides whether the card shows and
 * reports nothing back. It is asked for after a won hand, unprompted, so a failure does nothing: the store never opens.
 */
public final class PlayReview {
    private PlayReview() {}

    public static void ask(final Activity activity) {
        try {
            final ReviewManager manager = ReviewManagerFactory.create(activity);
            manager.requestReviewFlow().addOnCompleteListener(request -> {
                if (!request.isSuccessful()) {
                    Log.i("PlayReview", "review flow unavailable: " + request.getException());
                    return;
                }
                manager.launchReviewFlow(activity, request.getResult());
            });
        } catch (Throwable e) {
            Log.i("PlayReview", "review flow failed: " + e);
        }
    }
}
