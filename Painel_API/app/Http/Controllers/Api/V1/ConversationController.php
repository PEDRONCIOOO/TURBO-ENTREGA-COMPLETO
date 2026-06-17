<?php

namespace App\Http\Controllers\Api\V1;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\DeliveryMan;
use App\Models\UserInfo;
use App\Models\Message;
use App\Models\Order;
use App\Models\Vendor;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Modules\Rental\Entities\Trips;

class ConversationController extends Controller
{
    public function messages_store(Request $request)
    {
        if ($request->has('image')) {
            $image_name=[];
            foreach($request->file('image') as $key=>$img)
            {
                $name = Helpers::upload('conversation/', 'png', $img);
                $image_name[] = ['img'=>$name, 'storage'=> Helpers::getDisk()];
            }
        } else {
            $image_name = null;
        }

        $limit = $request['limit']??10;
        $offset = $request['offset']??1;
        $fcm_token_web = null;

        $sender = UserInfo::where('user_id', $request->user()->id)->first();
        if(!$sender){
            $sender = new UserInfo();
            $sender->user_id = $request->user()->id;
            $sender->f_name = $request->user()->f_name;
            $sender->l_name = $request->user()->l_name;
            $sender->phone = $request->user()->phone;
            $sender->email = $request->user()->email;
            $sender->image = $request->user()->image;
            $sender->save();
        }

        if($request->conversation_id){
            $conversation = Conversation::find($request->conversation_id);

            if($conversation->sender_id == $sender->id){
                $receiver_id = $conversation->receiver_id;
                $receiver = UserInfo::find($receiver_id);
                if($receiver->vendor_id){
                    $vendor = Vendor::find($receiver->vendor_id);
                    $fcm_token=$vendor->firebase_token;
                    $fcm_token_web = "store_panel_{$vendor->stores[0]->id}_message";
                }elseif($receiver->deliveryman_id){
                    $delivery_man = DeliveryMan::find($receiver->deliveryman_id);
                    $fcm_token=$delivery_man->fcm_token;
                }elseif($receiver->admin_id){
                    $receiver_id = 0;
                }
            }else{
                $receiver_id =$conversation->sender_id;
                $receiver = UserInfo::find($receiver_id);
                if($receiver->vendor_id){
                    $vendor = Vendor::find($receiver->vendor_id);
                    $fcm_token=$vendor->firebase_token;
                    $fcm_token_web = "store_panel_{$vendor->stores[0]->id}_message";
                }elseif($receiver->deliveryman_id){
                    $delivery_man = DeliveryMan::find($receiver->deliveryman_id);
                    $fcm_token=$delivery_man->fcm_token;
                }elseif($receiver->admin_id){
                    $receiver_id = 0;
                }
            }
        }else{
            if($request->receiver_type == 'admin'){
                $receiver_id = 0;
            }else if($request->receiver_type == 'vendor'){
                $receiver = UserInfo::where('vendor_id',$request->receiver_id)->first();
                $vendor = Vendor::find($request->receiver_id);
                if(!$receiver){
                    $receiver = new UserInfo();
                    $receiver->vendor_id = $vendor->id;
                    $receiver->f_name = $vendor->stores[0]->name;
                    $receiver->l_name = '';
                    $receiver->phone = $vendor->phone;
                    $receiver->email = $vendor->email;
                    $receiver->image = $vendor->stores[0]->logo;
                    $receiver->save();
                }

                $receiver_id = $receiver->id;
                $fcm_token=$vendor->firebase_token;
                $fcm_token_web = "store_panel_{$vendor->stores[0]->id}_message";

            }else if($request->receiver_type == 'delivery_man'){
                $receiver = UserInfo::where('deliveryman_id',$request->receiver_id)->first();
                $delivery_man = DeliveryMan::find($request->receiver_id);

                if(!$receiver){
                    $receiver = new UserInfo();
                    $receiver->deliveryman_id = $delivery_man->id;
                    $receiver->f_name = $delivery_man->f_name;
                    $receiver->l_name = $delivery_man->l_name;
                    $receiver->phone = $delivery_man->phone;
                    $receiver->email = $delivery_man->email;
                    $receiver->image = $delivery_man->image;
                    $receiver->save();
                }

                $receiver_id = $receiver->id;
                $fcm_token=$delivery_man->fcm_token;
            }

            $conversation = Conversation::WhereConversation($sender->id,$receiver_id)->first();
        }

        if(!$conversation){
            $conversation = new Conversation;
            $conversation->sender_id = $sender->id;
            $conversation->sender_type = 'customer';
            $conversation->receiver_id = $receiver_id;
            $conversation->receiver_type = $request->receiver_type;
            $conversation->unread_message_count = 0;
            $conversation->last_message_time = Carbon::now()->toDateTimeString();
            $conversation->save();
            $conversation= Conversation::find($conversation->id);
        }

        $message = new Message();
        $message->conversation_id = $conversation->id;
        $message->sender_id = $sender->id;
        $message->message = $request->message;
        $message->order_id = $request?->order_id ?? null;

        if($image_name && count($image_name)>0){
            $message->file = json_encode($image_name, JSON_UNESCAPED_SLASHES);
        }
        try {
            $message->save();
            $conversation->unread_message_count = $conversation->unread_message_count? $conversation->unread_message_count+1:1;
            $conversation->last_message_id=$message->id;
            $conversation->last_message_time = Carbon::now()->toDateTimeString();
            $conversation->save();
            {
                if($request->receiver_type == 'admin' || $receiver_id == 0){
                    $data = [
                        'title' =>translate('messages.message'),
                        'description' =>translate('messages.message_description'),
                        'order_id' => '',
                        'image' => '',
                        'message' => json_encode($message) ,
                        'type'=> 'message'
                    ];
                    Helpers::send_push_notif_to_topic($data,'admin_message','message');
                }else if($request->receiver_type == 'vendor' || $request->receiver_type == 'delivery_man'){
                    $data = [
                        'title' =>translate('messages.message'),
                        'description' =>translate('messages.message_description'),
                        'order_id' => '',
                        'image' => '',
                        'message' => json_encode($message) ,
                        'type'=> 'message',
                        'conversation_id'=> $conversation->id,
                        'sender_type'=> 'user'
                    ];
                    Helpers::send_push_notif_to_device($fcm_token, $data);
                    if($fcm_token_web){
                        Helpers::send_push_notif_to_topic($data, $fcm_token_web, 'message');
                    }

                }
            }

        } catch (\Exception $e) {
            info($e->getMessage());
        }

        $messages = Message::where(['conversation_id' => $conversation->id])->with('order')->latest()->paginate($limit, ['*'], 'page', $offset);
        $messages->getCollection()->transform(function ($message) {
            if ($message->order) {
                $message->order->delivery_address = gettype($message->order->delivery_address) == 'string' ? json_decode($message->order->delivery_address,true): $message->order->delivery_address;
                $message->order->id = (int) $message->order->id;
                $message->order->order_amount = (float) $message->order->order_amount;
                $message->order->details_count = (int) $message->order->details_count;
                }

            return $message;
        });

        $conv = Conversation::with('sender','receiver','last_message')->find($conversation->id);

        if($conv->sender_type == 'vendor' && $conversation->sender){
            $vd = Vendor::find($conv->sender->vendor_id);
            if($vd?->store?->module_type == 'rental' && addon_published_status('Rental')){
                $order = Trips::where('user_id',$request->user()->id)->where('provider_id', $vd->store->id)->whereIn('trip_status',['pending','confirmed','ongoing','completed'])->where('payment_status' ,'unpaid')->count();
            } else{
                $order = Order::where('user_id',$request->user()->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
            }
        }else if($conv->receiver_type == 'vendor' && $conversation->receiver){
            $vd = Vendor::find($conv->receiver->vendor_id);

            if($vd?->store?->module_type == 'rental' && addon_published_status('Rental')){
                $order = Trips::where('user_id',$request->user()->id)->where('provider_id', $vd->store->id)->whereIn('trip_status',['pending','confirmed','ongoing','completed'])->where('payment_status' ,'unpaid')->count();
            } else{
                $order = Order::where('user_id',$request->user()->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
            }
        }else if($conv->sender_type == 'delivery_man' && $conversation->sender){
            $user2 = DeliveryMan::find($conv->sender->deliveryman_id);
            $order = Order::where('user_id',$request->user()->id)->where('delivery_man_id', $user2->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
        }else if($conv->receiver_type == 'delivery_man' && $conversation->receiver){
            $user2 = DeliveryMan::find($conv->receiver->deliveryman_id);
            $order = Order::where('user_id',$request->user()->id)->where('delivery_man_id', $user2->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
        }
        else{
            $order=1;
        }


        $data =  [
            'total_size' => intval($messages->total()),
            'limit' => intval($limit),
            'offset' => intval($offset),
            'status' => ($order>0)?true:false,
            'message' => 'successfully sent!',
            'messages' => $messages->items(),
            'conversation' => $conv,
        ];
        return response()->json($data, 200);
    }

    public function chat_image(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'image' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        if ($request->has('image')) {
            $image_name = Helpers::upload('conversation/', 'png', $request->file('image'));
        } else {
            $image_name = 'def.png';
        }

        $url = asset('storage/app/public/conversation') . '/' . $image_name;

        return response()->json(['image_url' => $url], 200);
    }


    public function conversations(Request $request)
    {
        $limit = $request['limit']??10;
        $offset = $request['offset']??1;

        $sender = UserInfo::where('user_id', $request?->user()?->id)->first();
        if(!$sender){
            $sender = new UserInfo();
            $sender->user_id = $request?->user()?->id;
            $sender->f_name = $request?->user()?->f_name;
            $sender->l_name = $request?->user()?->l_name;
            $sender->phone = $request?->user()?->phone;
            $sender->email = $request?->user()?->email;
            $sender->image = $request?->user()?->image;
            $sender->save();
        }

        $conversations = Conversation::with('sender','receiver','last_message')
        ->where(function($q) use($sender){
                    $q->where(['sender_id' => $sender->id])->orWhere(['receiver_id' => $sender->id]);
                })
        ->when(isset($request->type) , function($query) use($request) {
            $query->where(function($q) use($request){
                $q->where('receiver_type', $request->type)->where('sender_type','customer')
                    ->orWhere(function($q) use($request){
                        $q->where('sender_type', $request->type)->where('receiver_type','customer');
                });
            });
        })
        ->orderBy('last_message_time', 'DESC')->paginate($limit, ['*'], 'page', $offset);

        $data =  [
            'type'=>$request->type ?? null,
            'total_size' => intval($conversations->total()),
            'limit' => intval($limit),
            'offset' => intval($offset),
            'conversations' => $conversations->items()
        ];
        return response()->json($data, 200);
    }

    public function search_conversations(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $key = explode(' ', $request['name']);

        $limit = $request['limit']??10;
        $offset = $request['offset']??1;

        $sender = UserInfo::where('user_id', $request->user()->id)->first();
        if(!$sender){
            $sender = new UserInfo();
            $sender->user_id = $request->user()->id;
            $sender->f_name = $request->user()->f_name;
            $sender->l_name = $request->user()->l_name;
            $sender->phone = $request->user()->phone;
            $sender->email = $request->user()->email;
            $sender->image = $request->user()->image;
            $sender->save();
        }

        $conversations = Conversation::with('sender','receiver','last_message')->WhereUser($sender->id)->where(function($qu)use($key){
                    $qu->whereHas('sender',function($query)use($key){
                    foreach ($key as $value) {
                        $query->where('f_name', 'like', "%{$value}%")->orWhere('l_name', 'like', "%{$value}%");
                    }
                })
                ->orWhereHas('receiver',function($query1)use($key){
                    foreach ($key as $value) {
                        $query1->where('f_name', 'like', "%{$value}%")->orWhere('l_name', 'like', "%{$value}%");
                    }
                });
            });

        $conversations = $conversations->orderBy('last_message_time', 'DESC')->paginate($limit, ['*'], 'page', $offset);

        $data =  [
            'total_size' => intval($conversations->total()),
            'limit' => intval($limit),
            'offset' => intval($offset),
            'conversations' => $conversations->items()
        ];
        return response()->json($data, 200);
    }

    public function messages(Request $request)
    {
        $limit = $request['limit']??10;
        $offset = $request['offset']??1;

        $user = UserInfo::where('user_id', $request->user()->id)->first();
        if(!$user){
            $user = new UserInfo();
            $user->user_id = $request->user()->id;
            $user->f_name = $request->user()->f_name;
            $user->l_name = $request->user()->l_name;
            $user->phone = $request->user()->phone;
            $user->email = $request->user()->email;
            $user->image = $request->user()->image;
            $user->save();
        }

        $conversation = null;
        if($request->conversation_id){
            $conversation = Conversation::with(['sender','receiver','last_message'])->find($request->conversation_id);
        }else if($request->has('admin_id')){
            $conversation = Conversation::with(['sender','receiver','last_message'])->WhereConversation($user->id,0)->first();
            $order=0;
        }else if($request->vendor_id){
            $vendor = UserInfo::where('vendor_id', $request->vendor_id)->first();
            if(!$vendor){
                $vd = Vendor::find($request->vendor_id);
                $vendor = new UserInfo();
                $vendor->vendor_id = $vd->id;
                $vendor->f_name = $vd->stores[0]->name;
                $vendor->l_name = '';
                $vendor->phone = $vd->phone;
                $vendor->email = $vd->email;
                $vendor->image = $vd->stores[0]->logo;
                $vendor->save();
            }
            $conversation = Conversation::with(['sender','receiver','last_message'])->WhereConversation($user->id,$vendor->id)->first();
        }else if($request->delivery_man_id){
            $dm = UserInfo::where('deliveryman_id', $request->delivery_man_id)->first();
            if(!$dm){
                $user2 = DeliveryMan::find($request->delivery_man_id);
                $dm = new UserInfo();
                $dm->deliveryman_id = $user2->id;
                $dm->f_name = $user2->f_name;
                $dm->l_name = $user2->l_name;
                $dm->phone = $user2->phone;
                $dm->email = $user2->email;
                $dm->image = $user2->image;
                $dm->save();
            }
            $conversation = Conversation::with(['sender','receiver','last_message'])->WhereConversation($user->id,$dm->id)->first();
        }

        if(isset($conversation)){
            if($conversation->sender_type == 'vendor' && $conversation->sender){
                $vd = Vendor::find($conversation->sender->vendor_id);
                if($vd?->store?->module_type == 'rental' && addon_published_status('Rental')){
                    $order = Trips::where('user_id',$request->user()->id)->where('provider_id', $vd->store->id)->whereIn('trip_status',['pending','confirmed','ongoing','completed'])->where('payment_status' ,'unpaid')->count();
                } else{
                    $order = Order::where('user_id',$request->user()->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
                }

            }else if($conversation->receiver_type == 'vendor' && $conversation->receiver){
                $vd = Vendor::find($conversation->receiver->vendor_id);
                if($vd?->store?->module_type == 'rental' && addon_published_status('Rental')){
                    $order = Trips::where('user_id',$request->user()->id)->where('provider_id', $vd->store->id)->whereIn('trip_status',['pending','confirmed','ongoing','completed'])->where('payment_status' ,'unpaid')->count();
                } else{
                    $order = Order::where('user_id',$request->user()->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
                }
            }else if($conversation->sender_type == 'delivery_man' && $conversation->sender){
                $user2 = DeliveryMan::find($conversation->sender->deliveryman_id);
                $order = Order::where('user_id',$user->user_id)->where('delivery_man_id', $user2->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
            }else if($conversation->receiver_type == 'delivery_man' && $conversation->receiver){
                $user2 = DeliveryMan::find($conversation->receiver->deliveryman_id);
                $order = Order::where('user_id',$user->user_id)->where('delivery_man_id', $user2->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
            }
            else{
                $order=1;
            }

            $lastmessage = $conversation->last_message;
            if($lastmessage && $lastmessage->sender_id != $user->id ) {
                $conversation->unread_message_count = 0;
                $conversation->save();
            }
            Message::where(['conversation_id' => $conversation->id])->where('sender_id','!=',$user->id)->update(['is_seen' => 1]);
            $messages = Message::where(['conversation_id' => $conversation->id])->with('order')->latest()->paginate($limit, ['*'], 'page', $offset);
            $messages->getCollection()->transform(function ($message) {
                if ($message->order) {
                    $message->order->delivery_address = gettype($message->order->delivery_address) == 'string' ? json_decode($message->order->delivery_address,true): $message->order->delivery_address;
                    $message->order->id = (int) $message->order->id;
                    $message->order->order_amount = (float) $message->order->order_amount;
                    $message->order->details_count = (int) $message->order->details_count;
                    }

                return $message;
            });
        }else{
            $messages =[];
            $order=0;
        }


        $data =  [
            'total_size' => $messages? intval($messages->total()):0,
            'limit' => intval($limit),
            'offset' => intval($offset),
            'status' => ($order > 0)?true:false,
            'messages' => $messages? $messages->items():[],
            'conversation' => $conversation
        ];
        return response()->json($data, 200);
    }

    public function dm_messages_store(Request $request)
    {

        if ($request->has('image')) {
            $image_name=[];
            foreach($request->file('image') as $key=>$img)
            {

                $name = Helpers::upload('conversation/', 'png', $img);
                array_push($image_name,['img'=>$name, 'storage'=> Helpers::getDisk()]);
            }
        } else {
            $image_name = null;
        }

        $limit = $request['limit']??10;
        $offset = $request['offset']??1;
        $fcm_token_web = null;

        $dm = DeliveryMan::where(['auth_token' => $request['token']])->first();

        $sender = UserInfo::where('deliveryman_id', $dm->id)->first();
        if(!$sender){
            $sender = new UserInfo();
            $sender->deliveryman_id = $dm->id;
            $sender->f_name = $dm->f_name;
            $sender->l_name = $dm->l_name;
            $sender->phone = $dm->phone;
            $sender->email = $dm->email;
            $sender->image = $dm->image;
            $sender->save();
        }

        if($request->conversation_id){
            $conversation = Conversation::find($request->conversation_id);

            if($conversation->sender_id == $sender->id){
                $receiver_id = $conversation->receiver_id;
                $receiver = UserInfo::find($receiver_id);
                if($receiver->vendor_id){
                    $vendor = Vendor::find($receiver->vendor_id);
                    $fcm_token=$vendor->firebase_token;
                    $fcm_token_web = "store_panel_{$vendor->stores[0]->id}_message";
                }elseif($receiver->user_id){
                    $user = User::find($receiver->user_id);
                    $fcm_token=$user->cm_firebase_token;
                }
            }else{
                $receiver_id =$conversation->sender_id;
                $receiver = UserInfo::find($receiver_id);
                if($receiver->vendor_id){
                    $vendor = Vendor::find($receiver->vendor_id);
                    $fcm_token=$vendor->firebase_token;
                    $fcm_token_web = "store_panel_{$vendor->stores[0]->id}_message";
                }elseif($receiver->user_id){
                    $user = User::find($receiver->user_id);
                    $fcm_token=$user->cm_firebase_token;
                }
            }
        }else{
            if($request->receiver_type == 'vendor'){
                // Resolve store via store_id / order_id / receiver_id
                $resolvedStore = null;
                $vendorWithoutScopes = function($q) { $q->withoutGlobalScopes(); };
                if($request->store_id){
                    $resolvedStore = \App\Models\Store::withoutGlobalScopes()->with(['vendor' => $vendorWithoutScopes])->find($request->store_id);
                }
                if(!$resolvedStore && $request->order_id){
                    $order = \App\Models\Order::withoutGlobalScopes()->find($request->order_id);
                    if($order) $resolvedStore = \App\Models\Store::withoutGlobalScopes()->with(['vendor' => $vendorWithoutScopes])->find($order->store_id);
                }
                if(!$resolvedStore && $request->receiver_id){
                    $resolvedStore = \App\Models\Store::withoutGlobalScopes()->with(['vendor' => $vendorWithoutScopes])->find($request->receiver_id);
                    if(!$resolvedStore){
                        $resolvedStore = \App\Models\Store::withoutGlobalScopes()->with(['vendor' => $vendorWithoutScopes])->where('vendor_id', $request->receiver_id)->first();
                    }
                }
                if(!$resolvedStore || !$resolvedStore->vendor){
                    return response()->json(['message' => 'Vendor not found'], 404);
                }
                $vendor = $resolvedStore->vendor;
                $receiver = UserInfo::where('vendor_id', $vendor->id)->first();
                if(!$receiver){
                    $receiver = new UserInfo();
                    $receiver->vendor_id = $vendor->id;
                    $receiver->f_name = $resolvedStore->name;
                    $receiver->l_name = '';
                    $receiver->phone = $vendor->phone;
                    $receiver->email = $vendor->email;
                    $receiver->image = $resolvedStore->logo;
                    $receiver->save();
                }
                $receiver_id = $receiver->id;
                $fcm_token = $vendor->firebase_token;
                $fcm_token_web = "store_panel_{$resolvedStore->id}_message";
            }else if($request->receiver_type == 'customer'){
                $receiver = UserInfo::where('user_id',$request->receiver_id)->first();
                $user = User::find($request->receiver_id);
                // dd($user);

                if(!$receiver){
                    $receiver = new UserInfo();
                    $receiver->user_id = $user->id;
                    $receiver->f_name = $user->f_name;
                    $receiver->l_name = $user->l_name;
                    $receiver->phone = $user->phone;
                    $receiver->email = $user->email;
                    $receiver->image = $user->image;
                    $receiver->save();
                }
                $receiver_id = $receiver->id;
                $fcm_token=$user->cm_firebase_token;
            }
        }

        // Robust conversation lookup: ANY UserInfo for this DM + ANY UserInfo for the same vendor
        $existingConv = null;
        if($request->receiver_type == 'vendor' && isset($vendor)){
            $vendorInfoIds2 = UserInfo::where('vendor_id', $vendor->id)->pluck('id');
            $dmInfoIds2 = UserInfo::where('deliveryman_id', $dm->id)->pluck('id');
            $existingConv = Conversation::where(function($q) use ($dmInfoIds2, $vendorInfoIds2) {
                $q->where(function($qq) use ($dmInfoIds2, $vendorInfoIds2) {
                    $qq->whereIn('sender_id', $dmInfoIds2)->whereIn('receiver_id', $vendorInfoIds2);
                })->orWhere(function($qq) use ($dmInfoIds2, $vendorInfoIds2) {
                    $qq->whereIn('receiver_id', $dmInfoIds2)->whereIn('sender_id', $vendorInfoIds2);
                });
            })->orderBy('last_message_time','DESC')->first();
        }
        $conversation = $existingConv ?: Conversation::WhereConversation($sender->id,$receiver_id)->first();

        // If we reused an existing conversation that points at a different DM UserInfo row,
        // realign $sender / $receiver_id with that conversation so message sender_id stays consistent.
        if($existingConv){
            if(in_array($existingConv->sender_id, $dmInfoIds2->toArray() ?? [])){
                $sender = UserInfo::find($existingConv->sender_id);
                $receiver_id = $existingConv->receiver_id;
            }else{
                $sender = UserInfo::find($existingConv->receiver_id);
                $receiver_id = $existingConv->sender_id;
            }
            $receiver = UserInfo::find($receiver_id);
        }

        if(!$conversation){
            $conversation = new Conversation;
            $conversation->sender_id = $sender->id;
            $conversation->sender_type = 'delivery_man';
            $conversation->receiver_id = $receiver->id;
            $conversation->receiver_type = $request->receiver_type;
            $conversation->unread_message_count = 0;
            $conversation->last_message_time = Carbon::now()->toDateTimeString();
            $conversation->save();
            $conversation= Conversation::find($conversation->id);
        }


        $message = new Message();
        $message->conversation_id = $conversation->id;
        $message->sender_id = $sender->id;
        $message->message = $request->message;
        if($image_name && count($image_name)>0){
            $message->file = json_encode($image_name, JSON_UNESCAPED_SLASHES);
        }
        try {
            if($message->save())
            $conversation->unread_message_count = $conversation->unread_message_count? $conversation->unread_message_count+1:1;
            $conversation->last_message_id=$message->id;
            $conversation->last_message_time = Carbon::now()->toDateTimeString();
            $conversation->save();
            {
                $data = [
                    'title' =>translate('messages.message_from')." ".$sender->f_name,
                    'description' => $message->message ?? translate('attachment'),
                    'order_id' => '',
                    'image' => '',
                    'message' => json_encode($message) ,
                    'type'=> 'message',
                    'conversation_id'=> $conversation->id,
                    'sender_type'=> 'delivery_man'
                ];
                Helpers::send_push_notif_to_device($fcm_token, $data);
                if($fcm_token_web){
                    Helpers::send_push_notif_to_topic($data, $fcm_token_web, 'message');
                }
            }

        } catch (\Exception $e) {
            info($e->getMessage());
        }

        $messages = Message::where(['conversation_id' => $conversation->id])->latest()->paginate($limit, ['*'], 'page', $offset);

        $conv = Conversation::with('sender','receiver','last_message')->find($conversation->id);

        if($conv->sender_type == 'vendor' && $conversation->sender){
            $vd = Vendor::withoutGlobalScopes()->with('stores')->find($conv->sender->vendor_id);
            $order = ($vd && isset($vd->stores[0])) ? Order::where('delivery_man_id',$dm->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count() : 0;
        }else if($conv->receiver_type == 'vendor' && $conversation->receiver){
            $vd = Vendor::withoutGlobalScopes()->with('stores')->find($conv->receiver->vendor_id);
            $order = ($vd && isset($vd->stores[0])) ? Order::where('delivery_man_id',$dm->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count() : 0;
        }else if($conv->sender_type == 'customer' && $conversation->sender){
            $user = User::find($conv->sender->user_id);
            $order = Order::where('delivery_man_id',$dm->id)->where('user_id', $user->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
        }else if($conv->receiver_type == 'customer' && $conversation->receiver){
            $user = User::find($conv->receiver->user_id);
            $order = Order::where('delivery_man_id',$dm->id)->where('user_id', $user->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
        }
        else{
            $order=0;
        }


        $data =  [
            'total_size' => intval($messages->total()),
            'limit' => intval($limit),
            'offset' => intval($offset),
            'status' => ($order>0)?true:false,
            'message' => 'successfully sent!',
            'messages' => $messages->items(),
            'conversation' => $conv,
        ];
        return response()->json($data, 200);
    }

    /**
     * GET /api/v1/delivery-man/message/store-details
     * Dedicated endpoint for DM ↔ Store chat — accepts store_id (not vendor_id).
     */
    public function dm_store_message_details(Request $request)
    {
        $limit  = $request['limit']  ?? 10;
        $offset = $request['offset'] ?? 1;

        $dm = DeliveryMan::where(['auth_token' => $request['token']])->first();
        if (!$dm) return response()->json(['message' => 'Unauthorized'], 401);

        // Ensure DM has a UserInfo record
        $dmInfo = UserInfo::where('deliveryman_id', $dm->id)->first();
        if (!$dmInfo) {
            $dmInfo = new UserInfo();
            $dmInfo->deliveryman_id = $dm->id;
            $dmInfo->f_name = $dm->f_name;
            $dmInfo->l_name = $dm->l_name;
            $dmInfo->phone = $dm->phone;
            $dmInfo->email = $dm->email;
            $dmInfo->image = $dm->image;
            $dmInfo->save();
        }

        $conversation = null;
        $storeId = $request->store_id;

        if ($request->conversation_id) {
            $conversation = Conversation::with(['sender', 'receiver', 'last_message'])
                ->find($request->conversation_id);
            // Try to infer store_id from conversation for the order-count below
            if (!$storeId && $conversation) {
                $otherInfo = ($conversation->sender_id == $dmInfo->id)
                    ? $conversation->receiver : $conversation->sender;
                if ($otherInfo && $otherInfo->vendor_id) {
                    $storeId = \App\Models\Store::where('vendor_id', $otherInfo->vendor_id)->value('id');
                }
            }
        } elseif ($request->store_id) {
            $store = \App\Models\Store::find($request->store_id);
            if (!$store) return response()->json(['message' => 'Store not found'], 404);

            $vendor = Vendor::find($store->vendor_id);
            if (!$vendor) return response()->json(['message' => 'Vendor not found'], 404);

            // Ensure vendor has a UserInfo record
            $vendorInfo = UserInfo::where('vendor_id', $vendor->id)->first();
            if (!$vendorInfo) {
                $vendorInfo = new UserInfo();
                $vendorInfo->vendor_id = $vendor->id;
                $vendorInfo->f_name = $store->name;
                $vendorInfo->l_name = '';
                $vendorInfo->phone = $vendor->phone;
                $vendorInfo->email = $vendor->email;
                $vendorInfo->image = $store->logo;
                $vendorInfo->save();
            }

            $conversation = Conversation::with(['sender', 'receiver', 'last_message'])
                ->WhereConversation($dmInfo->id, $vendorInfo->id)
                ->first();
        }

        $messages = null;
        if ($conversation) {
            $lastmsg = $conversation->last_message;
            if ($lastmsg && $lastmsg->sender_id != $dmInfo->id) {
                $conversation->unread_message_count = 0;
                $conversation->save();
            }
            Message::where('conversation_id', $conversation->id)
                ->where('sender_id', '!=', $dmInfo->id)
                ->update(['is_seen' => 1]);

            $messages = Message::where('conversation_id', $conversation->id)
                ->latest()->paginate($limit, ['*'], 'page', $offset);
        }

        // Count active orders (for status flag — always true for DM↔store)
        $order = $storeId
            ? Order::where('delivery_man_id', $dm->id)->where('store_id', $storeId)
                ->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])
                ->count()
            : 1;

        return response()->json([
            'total_size' => $messages ? intval($messages->total()) : 0,
            'limit'      => intval($limit),
            'offset'     => intval($offset),
            'status'     => true, // always allow DM to chat with store
            'messages'   => $messages ? $messages->items() : [],
            'conversation' => $conversation,
        ], 200);
    }

    /**
     * POST /api/v1/delivery-man/message/store-send
     * Dedicated endpoint for DM sending a message to a Store — accepts store_id.
     */
    public function dm_store_message_send(Request $request)
    {
        $image_name = null;
        if ($request->has('image')) {
            $image_name = [];
            foreach ($request->file('image') as $img) {
                $name = Helpers::upload('conversation/', 'png', $img);
                $image_name[] = ['img' => $name, 'storage' => Helpers::getDisk()];
            }
        }

        $limit  = $request['limit']  ?? 10;
        $offset = $request['offset'] ?? 1;

        $dm = DeliveryMan::where(['auth_token' => $request['token']])->first();
        if (!$dm) return response()->json(['message' => 'Unauthorized'], 401);

        // Ensure DM UserInfo
        $sender = UserInfo::where('deliveryman_id', $dm->id)->first();
        if (!$sender) {
            $sender = new UserInfo();
            $sender->deliveryman_id = $dm->id;
            $sender->f_name = $dm->f_name;
            $sender->l_name = $dm->l_name;
            $sender->phone = $dm->phone;
            $sender->email = $dm->email;
            $sender->image = $dm->image;
            $sender->save();
        }

        $fcm_token     = null;
        $fcm_token_web = null;
        $storeId       = $request->store_id;

        if ($request->conversation_id) {
            $conversation = Conversation::find($request->conversation_id);
            if (!$conversation) return response()->json(['message' => 'Conversation not found'], 404);

            $receiver_id = ($conversation->sender_id == $sender->id)
                ? $conversation->receiver_id : $conversation->sender_id;
            $receiver = UserInfo::find($receiver_id);

            if ($receiver && $receiver->vendor_id) {
                $vendor = Vendor::find($receiver->vendor_id);
                $fcm_token     = $vendor?->firebase_token;
                $storeObj      = $vendor?->stores[0] ?? null;
                $storeId       = $storeId ?? $storeObj?->id;
                $fcm_token_web = $storeObj ? "store_panel_{$storeObj->id}_message" : null;
            }
        } elseif ($request->store_id) {
            $store = \App\Models\Store::find($request->store_id);
            if (!$store) return response()->json(['message' => 'Store not found'], 404);

            $vendor = Vendor::find($store->vendor_id);
            if (!$vendor) return response()->json(['message' => 'Vendor not found'], 404);

            // Ensure vendor UserInfo
            $receiver = UserInfo::where('vendor_id', $vendor->id)->first();
            if (!$receiver) {
                $receiver = new UserInfo();
                $receiver->vendor_id = $vendor->id;
                $receiver->f_name = $store->name;
                $receiver->l_name = '';
                $receiver->phone = $vendor->phone;
                $receiver->email = $vendor->email;
                $receiver->image = $store->logo;
                $receiver->save();
            }

            $fcm_token     = $vendor->firebase_token;
            $fcm_token_web = "store_panel_{$store->id}_message";

            $conversation = Conversation::WhereConversation($sender->id, $receiver->id)->first();
            if (!$conversation) {
                $conversation = Conversation::create([
                    'sender_id'           => $sender->id,
                    'sender_type'         => 'delivery_man',
                    'receiver_id'         => $receiver->id,
                    'receiver_type'       => 'vendor',
                    'unread_message_count'=> 0,
                    'last_message_time'   => Carbon::now()->toDateTimeString(),
                ]);
                $conversation = Conversation::find($conversation->id);
            }
        } else {
            return response()->json(['message' => 'store_id or conversation_id is required'], 422);
        }

        // Save message
        $message = new Message();
        $message->conversation_id = $conversation->id;
        $message->sender_id       = $sender->id;
        $message->message         = $request->message;
        if ($image_name && count($image_name) > 0) {
            $message->file = json_encode($image_name, JSON_UNESCAPED_SLASHES);
        }
        try {
            $message->save();
            $conversation->unread_message_count = ($conversation->unread_message_count ?? 0) + 1;
            $conversation->last_message_id      = $message->id;
            $conversation->last_message_time    = Carbon::now()->toDateTimeString();
            $conversation->save();

            if ($fcm_token) {
                $data = [
                    'title'           => translate('messages.message_from') . ' ' . $sender->f_name,
                    'description'     => $message->message ?? translate('attachment'),
                    'order_id'        => '',
                    'image'           => '',
                    'message'         => json_encode($message),
                    'type'            => 'message',
                    'conversation_id' => $conversation->id,
                    'sender_type'     => 'delivery_man',
                ];
                Helpers::send_push_notif_to_device($fcm_token, $data);
                if ($fcm_token_web) {
                    Helpers::send_push_notif_to_topic($data, $fcm_token_web, 'message');
                }
            }
        } catch (\Exception $e) {
            info($e->getMessage());
        }

        $messages = Message::where('conversation_id', $conversation->id)
            ->latest()->paginate($limit, ['*'], 'page', $offset);
        $conv = Conversation::with('sender', 'receiver', 'last_message')->find($conversation->id);

        return response()->json([
            'total_size' => intval($messages->total()),
            'limit'      => intval($limit),
            'offset'     => intval($offset),
            'status'     => true,
            'message'    => 'successfully sent!',
            'messages'   => $messages->items(),
            'conversation' => $conv,
        ], 200);
    }

    public function dm_conversations(Request $request)
    {
        $limit = $request['limit']??10;
        $offset = $request['offset']??1;

        $delivery_man = DeliveryMan::where(['auth_token' => $request['token']])->first();

        $sender = UserInfo::where('deliveryman_id', $delivery_man->id)->first();
        if(!$sender){
            $sender = new UserInfo();
            $sender->deliveryman_id = $delivery_man->id;
            $sender->f_name = $delivery_man->f_name;
            $sender->l_name = $delivery_man->l_name;
            $sender->phone = $delivery_man->phone;
            $sender->email = $delivery_man->email;
            $sender->image = $delivery_man->image;
            $sender->save();
        }


        $conversations = Conversation::with('sender','receiver','last_message')->where(['sender_id' => $sender->id])->orWhere(['receiver_id' => $sender->id])->orderBy('last_message_time', 'DESC')->paginate($limit, ['*'], 'page', $offset);


        $data =  [
            'total_size' => intval($conversations->total()),
            'limit' => intval($limit),
            'offset' => intval($offset),
            'conversation' => $conversations->items()
        ];

        return response()->json($data, 200);
    }

    public function dm_search_conversations(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $key = explode(' ', $request['name']);

        $limit = $request['limit']??10;
        $offset = $request['offset']??1;

        $delivery_man = DeliveryMan::where(['auth_token' => $request['token']])->first();

        $sender = UserInfo::where('deliveryman_id', $delivery_man->id)->first();
        if(!$sender){
            $sender = new UserInfo();
            $sender->deliveryman_id = $delivery_man->id;
            $sender->f_name = $delivery_man->f_name;
            $sender->l_name = $delivery_man->l_name;
            $sender->phone = $delivery_man->phone;
            $sender->email = $delivery_man->email;
            $sender->image = $delivery_man->image;
            $sender->save();
        }

        $conversations = Conversation::with('sender','receiver','last_message')->WhereUser($sender->id)->where(function($qu)use($key){
                    $qu->whereHas('sender',function($query)use($key){
                    foreach ($key as $value) {
                        $query->where('f_name', 'like', "%{$value}%")->orWhere('l_name', 'like', "%{$value}%");
                    }
                })
                ->orWhereHas('receiver',function($query1)use($key){
                    foreach ($key as $value) {
                        $query1->where('f_name', 'like', "%{$value}%")->orWhere('l_name', 'like', "%{$value}%");
                    }
                });
            });

        $conversations = $conversations->orderBy('last_message_time', 'DESC')->paginate($limit, ['*'], 'page', $offset);

        $data =  [
            'total_size' => intval($conversations->total()),
            'limit' => intval($limit),
            'offset' => intval($offset),
            'conversation' => $conversations->items()
        ];
        return response()->json($data, 200);
    }


    public function dm_messages(Request $request)
    {
        $limit = $request['limit']??10;
        $offset = $request['offset']??1;

        $dm = DeliveryMan::where(['auth_token' => $request['token']])->first();
        $delivery_man = UserInfo::where('deliveryman_id',$dm->id)->first();

        if(!$delivery_man){
            $delivery_man = new UserInfo();
            $delivery_man->deliveryman_id = $dm->id;
            $delivery_man->f_name = $dm->f_name;
            $delivery_man->l_name = $dm->l_name;
            $delivery_man->phone = $dm->phone;
            $delivery_man->email = $dm->email;
            $delivery_man->image = $dm->image;
            $delivery_man->save();
        }

        if($request->conversation_id){
            $conversation = Conversation::with(['sender','receiver','last_message'])->find($request->conversation_id);
        }else if($request->order_id || $request->vendor_id || $request->store_id){
            // Resolve store via order_id / store_id / vendor_id
            $resolvedStore = null;
            $vendorWithoutScopes = function($q) { $q->withoutGlobalScopes(); };
            if($request->order_id){
                $order = \App\Models\Order::withoutGlobalScopes()->find($request->order_id);
                if($order && $order->store_id){
                    $resolvedStore = \App\Models\Store::withoutGlobalScopes()->with(['vendor' => $vendorWithoutScopes])->find($order->store_id);
                }
            }elseif($request->store_id){
                $resolvedStore = \App\Models\Store::withoutGlobalScopes()->with(['vendor' => $vendorWithoutScopes])->find($request->store_id);
            }elseif($request->vendor_id){
                $resolvedStore = \App\Models\Store::withoutGlobalScopes()->with(['vendor' => $vendorWithoutScopes])->where('vendor_id', $request->vendor_id)->first();
            }
            if(!$resolvedStore || !$resolvedStore->vendor) {
                // Mirror customer endpoint: return empty instead of 404
                $data = ['total_size' => 0, 'limit' => intval($limit), 'offset' => intval($offset), 'status' => false, 'messages' => [], 'conversation' => null];
                return response()->json($data, 200);
            }
            $vendorObj = $resolvedStore->vendor;
            $vendor = UserInfo::where('vendor_id', $vendorObj->id)->first();
            if(!$vendor){
                $vendor = new UserInfo();
                $vendor->vendor_id = $vendorObj->id;
                $vendor->f_name = $resolvedStore->name;
                $vendor->l_name = '';
                $vendor->phone = $vendorObj->phone;
                $vendor->email = $vendorObj->email;
                $vendor->image = $resolvedStore->logo;
                $vendor->save();
            }
            // Robust lookup: ANY UserInfo for this vendor + ANY UserInfo for this DM
            $vendorInfoIds = UserInfo::where('vendor_id', $vendorObj->id)->pluck('id');
            $dmInfoIds = UserInfo::where('deliveryman_id', $dm->id)->pluck('id');
            $conversation = Conversation::with(['sender','receiver','last_message'])
                ->where(function($q) use ($dmInfoIds, $vendorInfoIds) {
                    $q->where(function($qq) use ($dmInfoIds, $vendorInfoIds) {
                        $qq->whereIn('sender_id', $dmInfoIds)->whereIn('receiver_id', $vendorInfoIds);
                    })->orWhere(function($qq) use ($dmInfoIds, $vendorInfoIds) {
                        $qq->whereIn('receiver_id', $dmInfoIds)->whereIn('sender_id', $vendorInfoIds);
                    });
                })
                ->orderBy('last_message_time','DESC')
                ->first();

        }else if($request->user_id){
            $user = UserInfo::where('user_id', $request->user_id)->first();
            if(!$user){
                $customer = User::find($request->user_id);
                $user = new UserInfo();
                $user->user_id = $customer->id;
                $user->f_name = $customer->f_name;
                $user->l_name = $customer->l_name;
                $user->phone = $customer->phone;
                $user->email = $customer->email;
                $user->image = $customer->image;
                $user->save();
            }
            $conversation = Conversation::with(['sender','receiver','last_message'])->WhereConversation($delivery_man->id,$user->id)->first();
        }

        if($conversation){

            if($conversation->sender_type == 'vendor' && $conversation->sender){
                $vd = Vendor::withoutGlobalScopes()->with('stores')->find($conversation->sender->vendor_id);
                $order = $vd && isset($vd->stores[0]) ? Order::where('delivery_man_id',$dm->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count() : 0;
            }else if($conversation->receiver_type == 'vendor' && $conversation->receiver){
                $vd = Vendor::withoutGlobalScopes()->with('stores')->find($conversation->receiver->vendor_id);
                $order = $vd && isset($vd->stores[0]) ? Order::where('delivery_man_id',$dm->id)->where('store_id', $vd->stores[0]->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count() : 0;
            }else if($conversation->sender_type == 'customer' && $conversation->sender){
                $user = User::find($conversation->sender->user_id);
                $order = Order::where('delivery_man_id',$dm->id)->where('user_id', $user->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
            }else if($conversation->receiver_type == 'customer' && $conversation->receiver){
                $user = User::find($conversation->receiver->user_id);
                $order = Order::where('delivery_man_id',$dm->id)->where('user_id', $user->id)->whereIn('order_status', ['pending','accepted','confirmed','processing','handover','picked_up'])->count();
            }
            else{
                $order=0;
            }


            $lastmessage = $conversation->last_message;
            if($lastmessage && $lastmessage->sender_id != $delivery_man->id ) {
                $conversation->unread_message_count = 0;
                $conversation->save();
            }

            Message::where(['conversation_id' => $conversation->id])->where('sender_id','!=',$delivery_man->id)->update(['is_seen' => 1]);
            $messages = Message::where(['conversation_id' => $conversation->id])->latest()->paginate($limit, ['*'], 'page', $offset);
        }else{
            $messages =[];
            $order=0;
        }

        $data =  [
            'total_size' => $messages? intval($messages->total()):0,
            'limit' => intval($limit),
            'offset' => intval($offset),
            'status' => ($order>0)?true:false,
            'messages' => $messages? $messages->items():[],
            'conversation' => $conversation
        ];
        return response()->json($data, 200);
    }
}
