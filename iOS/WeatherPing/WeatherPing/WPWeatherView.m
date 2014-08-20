//
//  WPWeatherView.m
//  WeatherPing
//
//  Created by Nate Parrott on 8/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WPWeatherView.h"
#import <UIImage+ImageEffects.h>
#import "NSString+URLEncoded.h"

@interface WPWeatherView () <UIWebViewDelegate>

@property (nonatomic) IBOutlet UIImageView *placeholder;
@property (nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) IBOutlet UIView *refreshError;

@end

@implementation WPWeatherView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.webView.scrollView.scrollEnabled = NO;
}

- (NSString *)snapshotPath {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"screenshot.png"];
}

- (IBAction)refresh:(id)sender {
    self.refreshError.hidden = YES;
    NSString *weatherUrl = [PFInstallation currentInstallation][@"weatherURL"];
    if (weatherUrl) {
        NSString *webUrl = [NSString stringWithFormat:@"http://weatherping.parseapp.com/weather?url=%@", [weatherUrl URLEncodedString_ch]];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webUrl]]];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.placeholder.image = [UIImage imageWithContentsOfFile:[self snapshotPath]];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.placeholder.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.placeholder.alpha = 0;
    } completion:^(BOOL finished) {
        [self saveSnapshot];
    }];
}

- (void)saveSnapshot {
    if (self.webView.window) {
        UIGraphicsBeginImageContextWithOptions(self.webView.bounds.size, NO, 0);
        [self.webView drawViewHierarchyInRect:self.webView.bounds afterScreenUpdates:YES];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [UIImagePNGRepresentation([image applyBlurWithRadius:19 tintColor:nil saturationDeltaFactor:1 maskImage:nil]) writeToFile:[self snapshotPath] atomically:YES];
    }
}

@end
