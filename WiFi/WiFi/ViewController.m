//
//  ViewController.m
//  WiFi
//
//  Created by niuwan on 16/8/10.
//  Copyright © 2016年 niuwan. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
/**
 本Demo主要用到4个类：
 MCBrowserViewController:MCBrowserViewController继承自UIViewController，提供了基本的UI应用框架。
 
 MCAdvertiserAssistant、MCAdvertiserAssistant为针对Advertiser封装的管理助手,主要处理广播信息。
 
 MCSession:类似TCP链接中的socket。创建MCSession时，需指定自身MCPeerID，类似bind。
 
 MCPeerID:类似sockaddr，用于标识连接的两端endpoint，通常是昵称或设备名称。
 */
@interface ViewController ()<MCBrowserViewControllerDelegate, MCSessionDelegate>

{

    NSInteger noOfDataSend;
    
    NSInteger noOfData;
    
    NSMutableArray *marrReceiveData;
    
    NSMutableArray *marrFileData;
}

@property (nonatomic, strong) MCPeerID *myPeerID;
/**  <#Description#>  */
@property (nonatomic, strong) MCSession *mySession;
/**  m  */
@property (nonatomic, strong) MCBrowserViewController *browserVC;
/**  <#Description#>  */
@property (nonatomic, strong) MCAdvertiserAssistant *advertiser;

//图片
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    marrFileData = [NSMutableArray array];
    
    marrReceiveData = [NSMutableArray array];
    
}

- (IBAction)buttonShareClick:(UIButton *)sender {
    
    if (!self.mySession) {
        [self setupMultipeer];
    }
    
    [self showBrowserVC];
}

- (IBAction)buttonSendClick:(UIButton *)sender {
    
    [self sendData];
}


#pragma mark - 2、Multipeer Connectivity框架初始化这4个类。
- (void)setupMultipeer {

    //类似sockaddr，用于标识连接的两端endpoint，通常是昵称或设备名称
    self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    
    //类似TCP链接中的socket。创建MCSession时，需指定自身MCPeerID，类似bind。
    self.mySession = [[MCSession alloc] initWithPeer:self.myPeerID];
    self.mySession.delegate = self;
    
    //提供了基本的UI应用框架
    self.browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"chat" session:self.mySession];
    self.browserVC.delegate = self;
    
    //封装的管理助手,主要处理广播信息。
    self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"chat" discoveryInfo:nil session:self.mySession];
    
    [self.advertiser start];
    
}

- (void)showBrowserVC {

    [self presentViewController:self.browserVC animated:YES completion:nil];
}

- (void)dismissBrowserVC {

    [self.browserVC dismissViewControllerAnimated:YES completion:^{

        [self invokeAlertMethod:@"连接成功" Body:@"Both device connected successfully." Delegate:nil];
    }];
}

- (void)stopWifiSharing:(BOOL)isClear {

    if (isClear && self.mySession != nil) {
        
        [self.mySession disconnect];
        
        [self.mySession setDelegate:nil];
        
        self.mySession = nil;
        
        self.browserVC = nil;
    }

}

#pragma mark - 3、MCBrowserViewController 代理方法
//点击完成
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {

    [self dismissBrowserVC];
    
    [marrReceiveData removeAllObjects];
}

//点击取消
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {

    [self dismissBrowserVC];
}

#pragma mark - 4、MCSession代理方法  主要处理发送方传递的文件或者信息
// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    NSLog(@"data reseived long: %lu",(unsigned long)data.length);
    
    if (data.length > 0) {
        if (data.length < 2) {
            noOfDataSend++;
            NSLog(@"noOfdataSend:%zd", noOfDataSend);
            NSLog(@"array count:%zd", marrFileData.count);
            if (noOfDataSend < [marrFileData count]) {
                
                [self.mySession sendData:[marrFileData objectAtIndex:noOfDataSend] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
                
            }else {
            
                [self.mySession sendData:[@"File Transfer Done" dataUsingEncoding:NSUTF8StringEncoding] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
            }
        }else {
        
            if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"File Transfer Done"]) {

                [self appendFileData];
            }else {
            
                [self.mySession sendData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
                
                [marrReceiveData addObject:data];
            }
        }
    }
}


// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
    NSLog(@"did receive stream   streamName:%@", streamName);

}


// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {

    NSLog(@"start receiving  peerID ：%@", peerID);
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void) session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {

    NSLog(@"finish receiving resource resourceName:%@", resourceName);
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {

    NSLog(@"change state:%zd", state);
}

#pragma mark - 5、发送图片
//（此Demo只是简单地做了个收发图片的Demo，此框架可实现的功能当然不止这么简单。）

- (void)sendData {
    
    [marrFileData removeAllObjects];
    
    NSData *sendData = UIImagePNGRepresentation([UIImage imageNamed: @"test"]);
    
    self.imageView.image = [UIImage imageWithData:sendData];
    
    NSUInteger length = [sendData length];
    
    NSUInteger chunkSize = 100 * 1024;
    
    NSUInteger offset = 0;
    
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        
        NSData *chunk = [NSData dataWithBytesNoCopy:(char *)[sendData bytes] + offset length:thisChunkSize freeWhenDone:NO];
        
        NSLog(@"chunk length:%lu",(unsigned long)chunk.length);
        
        [marrFileData addObject:[NSData dataWithData:chunk]];
        
        offset += thisChunkSize;
        
    } while (offset < length);
    
    noOfData = [marrFileData count];
    
    noOfDataSend = 0;
    
    if ([marrFileData count] > 0) {
        [self.mySession sendData:[marrFileData objectAtIndex:noOfDataSend] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
    }

}

- (void)appendFileData {

    NSMutableData *fileData = [NSMutableData data];
    
    for (int i = 0; i < [marrReceiveData count]; i++) {
        
        [fileData appendData:[marrReceiveData objectAtIndex:i]];
        
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/Image.png", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    [fileData writeToFile:path atomically:YES];
    
    NSLog(@"Documents:%@", path);
    UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:fileData], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (!error) {
        [self invokeAlertMethod:@"发送成功" Body:@"图片已保存到手机相册" Delegate:nil];
    }
}

- (void)invokeAlertMethod:(NSString *)strTitle Body:(NSString *)strBody Delegate:(id)delegate
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strBody
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    alert = nil;
}



@end
